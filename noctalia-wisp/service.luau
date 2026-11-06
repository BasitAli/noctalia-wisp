--!nonstrict
-- Headless [[service]] — the ONLY entry that reads state.json or shells out.
--
-- Polls wispd's runtime state file, publishes a snapshot under "wisp", shows the
-- overlay while a turn is interesting, and runs `wispd choice <pick>` when the
-- overlay writes a "wisp_choice" request.

local DEFAULT_POLL_MS = 250
local DEFAULT_HIDE_MS = 5000

local ACTIVE = {
  listening = true,
  transcribing = true,
  deciding = true,
  acting = true,
  awaiting_choice = true,
  speaking = true,
  error = true,
}

local empty = {
  status = "offline",
  transcript = "",
  answer = "",
  result = "",
  choices = {},
  error = "",
  level = 0,
}

local lastRaw = ""
local shown = false
local hideAt = 0 -- epoch ms; 0 = no pending hide
local lastChoiceSeq = nil

local function cfg(key)
  return noctalia.getConfig(key)
end

local function intCfg(key: string, fallback: number, low: number, high: number): number
  local v = tonumber(cfg(key))
  if v == nil then
    return fallback
  end
  v = math.floor(v)
  if v < low then
    return low
  end
  if v > high then
    return high
  end
  return v
end

local function nowMs(): number
  return noctalia.nowMs()
end

local function statePath(): string
  local rt = noctalia.getenv("XDG_RUNTIME_DIR")
  if type(rt) ~= "string" or rt == "" then
    rt = "/tmp"
  end
  return rt .. "/wisp/state.json"
end

local PATH = statePath()

local function publish(snap)
  noctalia.state.set("wisp", snap)
end

local function interesting(snap): boolean
  if ACTIVE[snap.status] then
    return true
  end
  if type(snap.choices) == "table" and #snap.choices > 0 then
    return true
  end
  if type(snap.error) == "string" and snap.error ~= "" then
    return true
  end
  if type(snap.answer) == "string" and snap.answer ~= "" then
    return true
  end
  if type(snap.result) == "string" and snap.result ~= "" and snap.status == "done" then
    return true
  end
  return false
end

local function showOverlay()
  if not shown then
    noctalia.layer.show("overlay")
    shown = true
  end
  hideAt = 0
end

local function hideOverlay()
  if shown then
    noctalia.layer.hide("overlay")
    shown = false
  end
  hideAt = 0
end

local function scheduleHide()
  local ms = intCfg("hide_after_ms", DEFAULT_HIDE_MS, 0, 60000)
  if ms <= 0 then
    hideOverlay()
    return
  end
  hideAt = nowMs() + ms
end

local function normalize(decoded)
  local snap = {
    status = (type(decoded.status) == "string" and decoded.status) or "offline",
    transcript = (type(decoded.transcript) == "string" and decoded.transcript) or "",
    answer = (type(decoded.answer) == "string" and decoded.answer) or "",
    result = (type(decoded.result) == "string" and decoded.result) or "",
    error = (type(decoded.error) == "string" and decoded.error) or "",
    level = tonumber(decoded.level) or 0,
    choices = {},
  }
  if type(decoded.choices) == "table" then
    for _, c in ipairs(decoded.choices) do
      if type(c) == "string" and c ~= "" then
        table.insert(snap.choices, c)
      end
    end
  end
  return snap
end

local function refresh()
  local raw, err = noctalia.readFile(PATH)
  if not raw then
    if lastRaw ~= "" then
      lastRaw = ""
      publish(empty)
      hideOverlay()
    end
    return
  end
  if raw == lastRaw then
    if hideAt > 0 and nowMs() >= hideAt then
      hideOverlay()
    end
    return
  end
  lastRaw = raw

  local decoded, jerr = noctalia.json.decode(raw)
  if type(decoded) ~= "table" then
    noctalia.log("wisp: bad state.json: " .. tostring(jerr or "decode failed"))
    return
  end

  local snap = normalize(decoded)
  publish(snap)

  if interesting(snap) then
    showOverlay()
    if not ACTIVE[snap.status] and #(snap.choices) == 0 then
      -- Done / answered flash — auto-hide unless choices still need a click.
      scheduleHide()
    end
  else
    hideOverlay()
  end
end

local function runChoice(pick: string)
  if pick == "" then
    return
  end
  local wispd = noctalia.expandPath("~/.local/opt/wisp/wispd")
  if type(wispd) ~= "string" or wispd == "" then
    wispd = "wispd"
  end
  -- argv form (plugin_api 24) — no shell quoting
  noctalia.runAsync({ wispd, "choice", pick }, function(result)
    if result and result.exitCode ~= 0 then
      noctalia.log("wisp: choice failed: " .. tostring(result.stderr or result.exitCode))
    end
  end)
end

noctalia.state.watch("wisp_choice", function(req)
  if type(req) ~= "table" then
    return
  end
  local seq = req.seq
  if seq ~= nil and seq == lastChoiceSeq then
    return
  end
  lastChoiceSeq = seq
  local pick = req.pick
  if type(pick) == "string" and pick ~= "" then
    runChoice(pick)
  end
end)

noctalia.state.watch("wisp_dismiss", function(req)
  if type(req) ~= "table" then
    return
  end
  hideOverlay()
end)

function update()
  noctalia.setUpdateInterval(intCfg("poll_ms", DEFAULT_POLL_MS, 100, 2000))
  refresh()
end

publish(empty)
noctalia.setUpdateInterval(DEFAULT_POLL_MS)
