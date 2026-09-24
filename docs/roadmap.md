# Jelly: Roadmap

Jelly is in early development. Config keys and behaviour can change until the stable launch at v1.0.0.

## Next

- Saved SSH hosts under **Connect…**, opened as a tab or a session
- Per-host theme override (e.g. a red tint for Production)
- Custom Liquid Glass update sheet instead of Sparkle's default window

## Later

| Idea | Why |
|---|---|
| **Notes per directory** | Notes saved locally per project folder and exposed over MCP, so agents running in the terminal can read and write them. |
| **Quick Terminal** | Drop-down window on a global hotkey, over any app. |
| **Command blocks** | Built on OSC 133: fold, copy, or re-run a single command's output; jump between prompts. |
| **Per-project `jelly.toml`** | A project folder can define its own tabs, split layout, startup commands and theme (e.g. `dev`, `server`, `db`, `logs` opening together). |
| **Shell integration scripts** | Optional zsh and bash scripts for OSC 7 / OSC 133 where the prompt doesn't emit them. |
| **`xterm-jelly` terminfo** | Advertise exact capabilities instead of `xterm-256color`. |
| **Kitty graphics protocol** | Inline images for tools like `yazi`, `chafa`, `timg`. |
| **Broadcast input** | Type into every pane of a tab at once. |
| **Theme gallery** | Browse and install community themes from inside Jelly. |
| **Triggers** | Regex on output → highlight, notify, or run an action. |
| **Native notifications** | OSC 9 / OSC 777 and "long command finished" notifications. |
| **tmux control mode** | tmux windows and panes shown as native tabs and splits. |
| **Own renderer** | Replace SwiftTerm's view behind `TerminalSurface` if profiling shows it's the bottleneck (libghostty is an option). |

## Stable launch

v1.0.0 is the first stable release. Config keys and behaviour are settled from there.
