# Jelly: Product

Jelly is a native macOS terminal built around **sessions**: named workspaces that each hold their own tabs and split panes. It targets macOS 26+ and follows the Liquid Glass design language, with glass on the chrome and a crisp, readable terminal surface.

## Goals

- **Fast.** GPU-rendered, idle at 0% CPU, no dropped frames under heavy output.
- **Compatible.** Your shell, prompt, and font render exactly as they do in Ghostty or iTerm2: fish, zsh, bash, nu, starship, powerlevel10k, Nerd Fonts, ligatures, emoji.
- **Organized.** Sessions replace a pile of unnamed windows.
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
│            │ ⌁ zsh           ⑂ ⤢   │ ⌁ logs              │  pane headers
│            │                        │                     │
│            │        pane            │       pane          │
│            │                        │                     │
│ ⚡ Connect… │                        │                     │
│            │                ◉ dev · 3 panes · 112×28      │  status bar
└────────────┴──────────────────────────────────────────────┘
```

| Area | Behaviour |
|---|---|
| **Sessions** | Named workspaces (Work, Personal, Production…). Selecting one swaps every tab and pane. Create, rename, reorder, delete. Every window comes back on relaunch, in its place, with its sessions, tabs, splits and each pane's directory. Programs keep running when Jelly quits, crashes or updates itself: `claude`, a dev server or an SSH connection is still there after a relaunch, with the same screen and scrollback. When something is running, ⌘Q asks whether to quit and keep it running or **Quit and End Sessions**; **Jelly → Quit and End Sessions** (⌥⌘Q) ends them directly. Closing a pane or tab still ends its program. |
| **Connect…** | Saved SSH hosts (v0.3). |
| **Tab bar** | One tab per workspace view. Each has an icon and a title that follows the focused pane's process, or a name you set. Drag tabs to reorder them. Settings → Appearance switches between a glass capsule on the selected tab and rounded cards for every tab. `+` opens a tab, `⌕` opens search. |
| **Panes** | Split right or down, as deep as you like. Panes are detached cards with rounded corners and a gap between them; the focused one gets an accent border. Each has a header with its title and split, zoom and close buttons. Resize by dragging the gap between panes, double-click it to equalize. Click a pane to focus it. |
| **Status bar** | The agent that most needs you, on the left · session name · tab count · pane count when split · grid size of the focused pane (`112×28`). |
| **Agents** | Jelly notices Claude Code running in a pane (other agents such as Codex, Gemini CLI, OpenCode, Amp, Cursor Agent, Copilot CLI, Aider, Goose, Crush, Qwen Code, or your own can be switched on in Settings → Agents). Tabs and sessions show a small indicator: a spinning ring while it works, an amber dot (and an amber pane border) when it needs you, and a green dot when it finished while you were elsewhere, which clears once you look at the pane. The status bar shows the agent that most needs you; clicking it goes there. Claude Code's state comes from the status it writes for its own process; other agents are guessed from their output. When an agent needs you or finishes and you aren't looking at that pane, a macOS notification says so; clicking it brings the pane forward. ⌘⇧A jumps to the next agent that needs you (or is done), and the palette lists every agent in the window. |
| **Search** | Find in the focused pane's scrollback, with next/previous and match count. |
| **Explorer** | A read-only file tree on the right (⌘E) rooted at the focused pane's current directory. It follows the pane as you `cd` or switch panes, and updates live when files change, so you can watch an agent working in the terminal. Arrows move, → and ← open and close folders, ↩ or Space previews, ⌘↑ goes to the enclosing folder, typing filters, Esc returns to the terminal. |
| **Command palette** | ⌘K opens a search field over the window with every action, the current session's tabs, sessions and themes. Typing filters with fuzzy matching (word starts and runs rank first); ↑/↓ or ⌃P/⌃N move, ↩ runs, Esc or a click outside closes. The last few picks show first under Recent. Actions show their shortcut; the current tab, session and theme are checked. Moving onto a theme previews it live across the window without saving; Esc or a click outside puts the old one back, and picking it with ↩ writes it to `jelly.toml` (into the matching light or dark slot when the theme follows the system). |
| **Viewer** | ⌘⇧M, or ↩ in the explorer, opens a file over the panes. Markdown is rendered (headings, lists, task lists, tables, quotes, code, images) with a contents menu and working relative links; other text files show with line numbers. Code is syntax-highlighted in the theme's palette colours. It reloads when the file changes on disk. Esc closes it. Terminals behind it keep running. |

## Configuration and themes

Everything is plain TOML. A file can hold settings, keybinds, themes, or any mix.

- Your config lives at `~/.config/jelly/jelly.toml` and reloads live when saved.
- **Drop a `.toml` file** onto the window (or **File → Import…**), and Jelly shows what it will change ("adds 2 themes, changes 3 settings"). On confirm, it merges the file into your config.
- Bad config never breaks the app. Jelly keeps the last good values and shows a banner naming the line.

- **Settings window** (⌘,): General, Appearance, Terminal, Keybinds and Updates tabs. Every change is written straight into `jelly.toml` (comments kept) and applies at once. The Appearance tab lists the theme library (built-in themes plus `~/.config/jelly/themes/`) with a preview swatch, and picks one theme or a light/dark pair. The Keybinds tab lists every action by group; click a shortcut and press new keys to rebind it, with reset per action or for all.

Full reference: [config.md](config.md).

## Updates

Jelly updates itself. It checks once a day, offers the new version with release notes, and relaunches into your restored sessions. **Jelly → Check for Updates…** checks right away. The first launch after an update opens a What’s New window with that version’s release notes; **Jelly → What’s New…** reopens it.

The very first launch opens a Welcome window before any terminal: the Jelly icon, a line about sessions, and the key features (sessions, split panes, the built-in explorer, the command palette) with their current shortcuts. **Get Started** or closing it opens the first window. **Help → Welcome to Jelly** shows it again.


## Telemetry

Jelly sends anonymous usage data to PostHog so we know how many people use it and on which versions. It is on by default and turned off with **Settings → General → Share anonymous usage data** or `telemetry.enabled = false`.

- `app_launched` on every launch and `app_active` once per day, each with the app version, macOS version, CPU architecture, locale and a random install ID.
- Nothing typed, run or shown in a terminal is sent, and neither are paths, titles, commands or config.
- No person profiles and no GeoIP lookup. Debug builds never send anything.

## Key shortcuts (defaults)

| Action | Keys |
|---|---|
| New tab | ⌘T |
| Close pane (the tab when it's the last) | ⌘W |
| Close tab | ⌘⌥W |
| Split right | ⌘D |
| Split down | ⌘⇧D |
| Focus pane | ⌘⌥ arrows |
| Zoom pane | ⌘⇧↩ |
| Equalize panes | ⌘⌃= |
| Next / previous tab | ⌘⇧] / ⌘⇧[ |
| Move tab left / right | ⌘⇧← / ⌘⇧→ |
| Tab 1–9 | ⌘1 … ⌘9 |
| New session | ⌘⇧N |
| Next / previous session | ⌘⌃] / ⌘⌃[ |
| Session 1–9 | ⌘⌃1 … ⌘⌃9 |
| Toggle sidebar | ⌘0 |
| Toggle explorer | ⌘E |
| Preview Markdown (selected file, or the directory's README) | ⌘⇧M |
| Command palette | ⌘K |
| Jump to waiting agent | ⌘⇧A |
| Find | ⌘F |
| Clear | ⌘⇧K |
| Reload config | ⌘⇧, |
| Settings | ⌘, |

All shortcuts can be rebound in `[keybinds]`.
