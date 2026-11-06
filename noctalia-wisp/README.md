# Noctalia Wisp

Corner card for the [Wisp](https://github.com/duketopceo/wisp) voice daemon while a turn is
active: status, transcript, answer, and choice buttons.

**Settings / Activity / Memory** stay in the Quickshell management Panel
(`quickshell -n -p ~/.local/opt/wisp/shells/debug`) — this plugin does not replace that.

## Entries

| Entry | Role |
|---|---|
| `basitali/noctalia-wisp:service` | Polls `$XDG_RUNTIME_DIR/wisp/state.json`, shows/hides the layer, runs `wispd choice` |
| `basitali/noctalia-wisp:overlay` | Bottom-right layer-shell card (`plugin_api` 36) |

## Enable

```fish
noctalia msg plugins enable basitali/noctalia-wisp
```

Requires Noctalia ≥ 5.4.0 (`[[layer]]`) and a running `wispd`.
