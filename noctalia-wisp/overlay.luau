--!nonstrict
-- [[layer]] entry — corner card for a live Wisp turn.
--
-- Pure presentation. Reads the "wisp" snapshot; choice / dismiss write request
-- keys the service handles. Settings stay in the Quickshell management Panel.

local seq = ((tonumber(noctalia.formatTime("%s")) or 0) * 2) + 1

local function tr(key: string, subst: table?): string
  if subst then
    return noctalia.tr(key, subst)
  end
  return noctalia.tr(key)
end

local function snapshot()
  local s = noctalia.state.get("wisp")
  if type(s) ~= "table" then
    return {
      status = "offline",
      transcript = "",
      answer = "",
      result = "",
      choices = {},
      error = "",
      level = 0,
    }
  end
  return s
end

local function statusWord(status: string): string
  if status == "listening" then
    return tr("status.listening")
  elseif status == "transcribing" then
    return tr("status.hearing")
  elseif status == "deciding" then
    return tr("status.thinking")
  elseif status == "acting" then
    return tr("status.working")
  elseif status == "awaiting_choice" then
    return tr("status.needs_you")
  elseif status == "speaking" then
    return tr("status.speaking")
  elseif status == "error" then
    return tr("status.error")
  elseif status == "done" then
    return tr("status.done")
  end
  return status
end

local function statusColor(status: string): string
  if status == "error" then
    return "error"
  elseif status == "listening" then
    return "primary"
  elseif status == "transcribing" or status == "deciding" then
    return "secondary"
  elseif status == "acting" or status == "awaiting_choice" then
    return "tertiary"
  elseif status == "speaking" then
    return "primary"
  end
  return "on_surface_variant"
end

function onDismissClicked()
  seq += 2
  noctalia.state.set("wisp_dismiss", { seq = seq })
end

local function requestChoice(pick: string)
  seq += 2
  noctalia.state.set("wisp_choice", { pick = pick, seq = seq })
end

local function render()
  local s = snapshot()
  local children = {
    ui.row({ align = "center", justify = "space_between", gap = 8 }, {
      ui.row({ align = "center", gap = 8, flexGrow = 1 }, {
        ui.glyph({ name = "microphone", size = 18, color = statusColor(s.status) }),
        ui.label({
          text = statusWord(s.status),
          fontWeight = "bold",
          color = statusColor(s.status),
        }),
      }),
      ui.button({ glyph = "close", variant = "ghost", onClick = "onDismissClicked" }),
    }),
  }

  if s.transcript ~= "" then
    table.insert(children, ui.label({
      text = s.transcript,
      fontSize = 13,
      color = "on_surface",
    }))
  end

  if s.answer ~= "" then
    table.insert(children, ui.separator())
    table.insert(children, ui.label({
      text = s.answer,
      fontSize = 13,
      color = "on_surface_variant",
    }))
  elseif s.result ~= "" and s.status == "done" then
    table.insert(children, ui.separator())
    table.insert(children, ui.label({
      text = s.result,
      fontSize = 12,
      color = "on_surface_variant",
    }))
  end

  if s.error ~= "" then
    table.insert(children, ui.label({
      text = s.error,
      fontSize = 12,
      color = "error",
    }))
  end

  if type(s.choices) == "table" and #s.choices > 0 then
    local buttons = {}
    for _, pick in ipairs(s.choices) do
      local label = pick
      table.insert(buttons, ui.button({
        text = label,
        variant = "secondary",
        controlSize = "sm",
        onClick = function()
          requestChoice(label)
        end,
      }))
    end
    table.insert(children, ui.row({ gap = 6, align = "center" }, buttons))
  end

  layer.render(ui.column({
    gap = 10,
    padding = 14,
    fill = "surface_container/0.92",
    radius = 16,
    border = "outline_variant/0.4",
    borderWidth = 1,
    minWidth = 280,
  }, children))
end

function update()
  render()
end

noctalia.state.watch("wisp", function(_value)
  render()
end)

render()
