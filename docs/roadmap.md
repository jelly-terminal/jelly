# Jelly: Roadmap

Everything before v1 is a preview. Config keys and behaviour can change between versions.

## v0.1: Core terminal

- AppKit shell with a single window, SwiftUI chrome, Liquid Glass tab bar and status bar
- `JellyTerminal`: PTY, SwiftTerm engine, query responder, key and mouse encoding
- Metal renderer: glyph atlases, fallback fonts, ligatures, emoji, built-in box drawing and powerline
- Tabs
- `jelly.toml` with live reload, error banner, built-in themes, TOML import with preview
- Sparkle updates and the release pipeline
- Unit tests from [tech.md](tech.md#testing)

**Done when:** fish + starship with FiraCode Nerd Font looks identical to Ghostty, nvim and tmux work, and a release updates to the next one.

## v0.2: Workspace

- Split panes with headers, zoom, keyboard focus
- Sidebar: Sessions and Projects
- Session and layout restore on relaunch and after updates
- Search in scrollback
- Status bar details (session, pane count, grid size)

## v0.3: Connect

- Saved SSH hosts under **Connect…**, opened as a tab or a session
- Per-host theme override (e.g. a red tint for Production)
- Custom Liquid Glass update sheet instead of Sparkle's default window

## Later

| Idea | Why |
|---|---|
| **Notes per directory** | Notes saved locally per project folder and exposed over MCP, so agents running in the terminal can read and write them. |
| **Command palette** (⌘K) | Every action, session, project and theme in one searchable list. |
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
| **libghostty-vt engine** | Swap in behind `TerminalEngine` if profiling shows the parser is the bottleneck. |
