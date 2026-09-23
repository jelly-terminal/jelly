# Jelly: Product

Jelly is a native macOS terminal built around **sessions**: named workspaces that each hold their own tabs and split panes. It targets macOS 26+ and follows the Liquid Glass design language, with glass on the chrome and a crisp, readable terminal surface.

## Goals

- **Fast.** GPU-rendered, idle at 0% CPU, no dropped frames under heavy output.
- **Compatible.** Your shell, prompt, and font render exactly as they do in Ghostty or iTerm2: fish, zsh, bash, nu, starship, powerlevel10k, Nerd Fonts, ligatures, emoji.
- **Organized.** Sessions and projects replace a pile of unnamed windows.
- **Configurable in plain text.** One `jelly.toml` for settings and themes. Drop any TOML file on the window to merge it in.
- **Native.** SwiftUI and AppKit, not a web view.

## Non-goals (for now)

- Windows or Linux builds.
- Mac App Store distribution (a terminal can't run inside the App Sandbox).
- A plugin system.

## Window anatomy

```
┌────────────┬──────────────────────────────────────────────┐
│ ● ● ●    ◐ │ [dev ×] [server] [db] [logs]  +            ⌕ │  tab bar
│            ├──────────────────────────────────────────────┤
│ Sessions + │                                              │
│  ▸ Work    │                 pane                         │
│    Personal│                                              │
│    ...     ├────────────────────────┬─────────────────────┤
│ Projects   │ ⌁ zsh           ⑂ ⤢   │ ⌁ logs              │  pane headers
│    aurora  │                        │                     │
│    ...     │        pane            │       pane          │
│            │                        │                     │
│ ⚡ Connect… │                        │                     │
│            │                ◉ dev · 3 panes · 112×28      │  status bar
└────────────┴──────────────────────────────────────────────┘
```

| Area | Behaviour |
|---|---|
| **Sessions** | Named workspaces (Work, Personal, Production…). Selecting one swaps every tab and pane. Create, rename, reorder, delete. Restored on relaunch. |
| **Projects** | Saved folders. Click to open a new tab in that folder in the current session. Add by dragging a folder onto the list or with `+`. |
| **Connect…** | Saved SSH hosts (v0.3). |
| **Tab bar** | One tab per workspace view. Each has an icon and a title that follows the running process, or a name you set. `+` opens a tab, `⌕` opens search. |
| **Panes** | Split right or down, as deep as you like. Each pane has a header with its title and split/zoom buttons. Resize by dragging the divider. |
| **Status bar** | Session name · tab count · grid size of the focused tab (`112×28`). |
| **Search** | Find in the focused pane's scrollback, with next/previous and match count. |

## Configuration and themes

Everything is plain TOML. A file can hold settings, keybinds, themes, or any mix.

- Your config lives at `~/.config/jelly/jelly.toml` and reloads live when saved.
- **Drop a `.toml` file** onto the window (or **File → Import…**), and Jelly shows what it will change ("adds 2 themes, changes 3 settings"). On confirm, it merges the file into your config.
- Bad config never breaks the app. Jelly keeps the last good values and shows a banner naming the line.

Full reference: [config.md](config.md).

## Updates

Jelly updates itself. It checks once a day, offers the new version with release notes, and relaunches into your restored sessions. **Jelly → Check for Updates…** checks right away.

## Key shortcuts (defaults)

| Action | Keys |
|---|---|
| New tab | ⌘T |
| Close pane / tab | ⌘W |
| Split right | ⌘D |
| Split down | ⌘⇧D |
| Focus pane | ⌘⌥ arrows |
| Zoom pane | ⌘⇧↩ |
| Next / previous tab | ⌘⇧] / ⌘⇧[ |
| Tab 1–9 | ⌘1 … ⌘9 |
| New session | ⌘⇧N |
| Toggle sidebar | ⌘0 |
| Find | ⌘F |
| Reload config | ⌘⇧, |
| Settings (opens config) | ⌘, |

All shortcuts can be rebound in `[keybinds]`.
