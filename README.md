# noctalia-wisp

Native [Noctalia](https://github.com/noctalia-dev/noctalia) v5 plugin: a corner
`[[layer]]` overlay for the [Wisp](https://github.com/duketopceo/wisp) voice
daemon (status, transcript, answer, choice buttons).

Settings / Activity stay in Wisp’s Quickshell management Panel — this plugin
only surfaces live turns.

## Requirements

- Noctalia ≥ **5.4.0** (`plugin_api` 36 — `[[layer]]` entries)
- A running `wispd` (Wisp installs under `~/.local/opt/wisp`)

## Install

Add as a plugin source, then enable:

```toml
[[plugins.source]]
kind = "git"
location = "https://github.com/BasitAli/noctalia-wisp"
name = "noctalia-wisp"
```

```fish
noctalia msg plugins enable basitali/noctalia-wisp
```

Or: Settings → Plugins after the source is loaded.

## Layout

```
catalog.toml          # Noctalia source index
noctalia-wisp/        # the plugin
  plugin.toml
  service.luau
  overlay.luau
  translations/
```

## License

MIT
