# Jelly: Configuration

All configuration is plain TOML. A file can contain any mix of `[settings]`, `[keybinds]` and `[[theme]]`.

## Where config lives

| Path | What |
|---|---|
| `~/.config/jelly/jelly.toml` | Your settings and keybinds. Created with commented defaults on first launch. |
| `~/.config/jelly/themes/*.toml` | Your themes, one or more per file. |
| `Jelly.app/Contents/Resources/Themes/` | Built-in themes. |

`$XDG_CONFIG_HOME` is used instead of `~/.config` when set.

Changes apply live as soon as the file is saved. **⌘,** opens the Settings window, which edits this same file in place: it only writes the keys you change and keeps your comments. **Jelly → Open Config File…** opens `jelly.toml` in your default editor, and **⌘⇧,** forces a reload.

Font fallback, OpenType features, cell size, shell arguments and shell environment are only set in the file.

When the Keybinds tab takes a default shortcut away from an action, it writes that shortcut as `"none"`. Resetting an action removes its lines from `[keybinds]`.

## Importing a TOML file

Drag any `.toml` file onto a Jelly window, or use **File → Import…** (⌘⇧I). Jelly shows a preview of what will change, then on confirm:

- `[settings]` and `[keybinds]` keys are written into `jelly.toml`, one key at a time. Keys not in the file are left alone. Your comments and ordering are kept.
- Each `[[theme]]` is saved to `themes/<id>.toml`, replacing any theme with the same `id`.
- If the file has only themes, Jelly asks whether to switch to the first one.

## Errors

An invalid value never stops Jelly from loading. That key falls back to its default, the rest of the file still applies, and a banner shows the file, line and problem. Unknown keys are reported the same way, so typos don't go unnoticed.

## Full example

```toml
[settings]
theme = "midnight"
scrollback = 10000
confirm-quit = true

[settings.font]
family = "FiraCode Nerd Font"
size = 13
fallback = ["Symbols Nerd Font Mono", "Apple Color Emoji"]
ligatures = true
features = ["calt", "zero", "ss02"]
thicken = false
cell-width = "100%"
cell-height = "110%"

[settings.window]
background-opacity = 0.92
blur = 20
padding = { x = 10, y = 8 }
sidebar = true
status-bar = true

[settings.cursor]
style = "block"
blink = true

[settings.shell]
program = "/opt/homebrew/bin/fish"
args = ["-l"]
working-directory = "inherit"
env = { EDITOR = "nvim" }

[settings.clipboard]
copy-on-select = false
osc52-read = false

[settings.updates]
check = true
auto-install = false

[keybinds]
"cmd+d" = "split.right"
"cmd+shift+d" = "split.down"
"cmd+shift+k" = "clear"
"cmd+shift+enter" = "pane.zoom"

[[theme]]
id = "midnight"
name = "Midnight"
appearance = "dark"
background = "#0f1117"
foreground = "#c9d1d9"
cursor = "#e6edf3"
cursor-text = "#0f1117"
selection = "#264f78"
selection-text = "#ffffff"
palette = [
  "#1b1f27", "#ff7b72", "#7ee787", "#d29922",
  "#79c0ff", "#d2a8ff", "#56d4dd", "#c9d1d9",
  "#6e7681", "#ffa198", "#a5f5b0", "#e3b341",
  "#a5d6ff", "#e2c5ff", "#b3f0ff", "#ffffff",
]
```

## Settings reference

| Key | Type | Default | Notes |
|---|---|---|---|
| `theme` | string | `"jelly-dark"` | A theme `id`. `{ light = "a", dark = "b" }` follows system appearance. |
| `scrollback` | int | `10000` | Lines per pane. |
| `confirm-quit` | bool | `true` | Ask before quitting with running processes. |
| `font.family` | string | `"SF Mono"` | Any installed family. Matched ignoring case, spaces and hyphens. |
| `font.size` | number | `13` | Points. |
| `font.fallback` | [string] | `[]` | Tried before the system fallback list. When empty and the main font has no Nerd Font icons, an installed Nerd Font is added automatically. |
| `font.ligatures` | bool | `true` | |
| `font.features` | [string] | `[]` | OpenType feature tags. Prefix with `-` to disable, e.g. `"-liga"`. |
| `font.thicken` | bool | `false` | Heavier strokes on low-DPI displays. |
| `font.cell-width` / `cell-height` | string | `"100%"` | Percentage or pixels (`"+2"`, `"-1"`). |
| `window.background-opacity` | number | `1.0` | `0.0`–`1.0`. |
| `window.blur` | int | `0` | Blur radius behind a transparent background. |
| `window.padding` | table | `{ x = 10, y = 8 }` | Points between each pane's edge and its grid (`y` is the bottom; the header sits on top). |
| `window.sidebar` | bool | `true` | Show the sidebar on launch. |
| `window.status-bar` | bool | `true` | |
| `cursor.style` | string | `"block"` | `block`, `bar`, `underline`. |
| `cursor.blink` | bool | `true` | |
| `shell.program` | string | login shell | Absolute path. |
| `shell.args` | [string] | `[]` | The shell always starts as a login shell. |
| `shell.working-directory` | string | `"inherit"` | `inherit` (from focused pane), `home`, or a path. |
| `shell.env` | table | `{}` | Extra environment variables. |
| `clipboard.copy-on-select` | bool | `false` | |
| `clipboard.osc52-read` | bool | `false` | Let programs read the clipboard. Write is always allowed. |
| `updates.check` | bool | `true` | Daily update check. |
| `updates.auto-install` | bool | `false` | Download in the background and install on quit. |

## Keybind actions

Keys are written as `modifiers+key`, with modifiers `cmd`, `shift`, `alt` (or `opt`), `ctrl`. Set an action to `"none"` to unbind a default.

`tab.new`, `tab.close`, `tab.next`, `tab.previous`, `tab.goto:<n>`, `tab.move:left|right`, `tab.rename`, `split.right`, `split.down`, `pane.close`, `pane.zoom`, `pane.focus:left|right|up|down`, `pane.equalize`, `session.new`, `session.next`, `session.previous`, `session.goto:<n>`, `sidebar.toggle`, `explorer.toggle`, `markdown.preview`, `palette.toggle`, `find`, `clear`, `copy`, `paste`, `font.increase`, `font.decrease`, `font.reset`, `settings.open`, `config.open`, `config.reload`, `prompt.previous`, `prompt.next`, `text:<string>` (sends literal text; supports `\n`, `\x1b`).

## Theme reference

| Key | Required | Notes |
|---|---|---|
| `id` | yes | Lowercase, hyphens. Used by `settings.theme`. |
| `name` | yes | Shown in the theme picker. |
| `appearance` | no | `dark` or `light`. Used for `{ light, dark }` pairing and chrome tint. |
| `background`, `foreground` | yes | Hex: `#rgb`, `#rrggbb` or `#rrggbbaa`. |
| `palette` | yes | Exactly 16 colors, ANSI 0–15. |
| `cursor`, `cursor-text` | no | Default to `foreground` / `background`. |
| `selection`, `selection-text` | no | |
| `accent` | no | Tints sidebar selection and tab highlight. Defaults to palette 4. |
