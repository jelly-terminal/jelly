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
| **Sessions** | Named workspaces (Work, Personal, Production…). Selecting one swaps every tab and pane. Create, rename, delete, and drag them in the sidebar to reorder. Right-click a session → **Color** to pick blue (the default), green, yellow, red or purple; the colour comes from the theme's palette and tints the session's icon in the sidebar, the terminal icon on its tabs and the dot in the status bar. Hold ⌃ and press ⇥ (⌃⇧⇥ goes back) to bring up the session switcher, like ⌘⇥ for apps: a tile per session, most recently used first with the current one on the left, with its initial in the session's colour and its agent state, and the selected session's name and tab count underneath. Keep pressing ⇥ or use ← → to move, let go of ⌃ to switch; Esc cancels, and clicking a tile switches to it. A quick ⌃⇥ goes back to the last session you used without showing it. ⌘⌃] and ⌘⌃[ work the same way. Every window comes back on relaunch, in its place, with its sessions, tabs, splits and each pane's directory. Programs keep running when Jelly quits, crashes or updates itself: `claude`, a dev server or an SSH connection is still there after a relaunch, with the same screen and scrollback. When something is running, ⌘Q asks whether to quit and keep it running or **Quit and End Sessions**; **Jelly → Quit and End Sessions** (⌥⌘Q) ends them directly. Closing a pane or tab still ends its program. |
| **Connect…** | Saved SSH hosts (v0.3). |
| **Tab bar** | One tab per workspace view. Each has an icon and a title that follows the focused pane's process, or a name you set. Drag tabs to reorder them. Settings → Appearance switches between a glass capsule on the selected tab and rounded cards for every tab. `+` opens a tab, `⌕` opens search. |
| **Panes** | Split right or down, as deep as you like. Panes are detached cards with rounded corners and a gap between them; the focused one gets an accent border. Each has a header with its title and split, zoom and close buttons. Resize by dragging the gap between panes, double-click it to equalize. Click a pane to focus it. |
| **Status bar** | The agent that most needs you, on the left · a dot in the session's colour and its name · tab count · pane count when split · grid size of the focused pane (`112×28`). |
| **Agents** | Jelly notices Claude Code running in a pane (other agents such as Codex, Gemini CLI, OpenCode, Amp, Cursor Agent, Copilot CLI, Aider, Goose, Crush, Qwen Code, or your own can be switched on in Settings → Agents). Tabs and sessions show a small indicator: a spinning ring while it works, an amber dot (and an amber pane border) when it needs you, and a green dot when it finished while you were elsewhere, which clears once you look at the pane. The status bar shows the agent that most needs you; clicking it goes there. Claude Code's state comes from the status it writes for its own process; other agents are guessed from their output. When an agent needs you or finishes and you aren't looking at that pane, a macOS notification says so; clicking it brings the pane forward. ⌘⇧A jumps to the next agent that needs you (or is done), and the palette lists every agent in the window. |
| **Search** | Find in the focused pane's scrollback, with next/previous and match count. |
| **Explorer** | A read-only file tree on the right (⌘E) rooted at the focused pane's current directory. It follows the pane as you `cd` or switch panes, and updates live when files change, so you can watch an agent working in the terminal. Arrows move, → and ← open and close folders, ↩ or Space previews, ⌘↑ goes to the enclosing folder, typing filters, Esc returns to the terminal. |
| **Activity** | **Toggle Activity** in the command palette (or View menu) opens a small card over the panes with three tabs. **Processes** lists what runs in each pane of the window, grouped by pane: the command (`npm run dev`, `claude`), its session and tab, how long it has run, and CPU and memory for the whole process tree, with busy panes first and idle shells dimmed. The chevron expands a pane into its process tree; clicking a pane goes to it. Below, **Other** shows your busiest processes outside Jelly. **Ports** lists every TCP port your processes listen on, those started from a Jelly pane first with their session and tab; clicking one opens `http://localhost:<port>`, and a globe marks ports reachable from other devices on your network. **System** shows CPU, memory and network speed with a two-minute graph each, and the load average. Right-click a row to interrupt, terminate or force quit it, copy its PID or URL, or show its pane. Drag the card by its header to any corner of the pane area; it stays there and remembers its tab. It measures every 2 seconds, only while it's open. It has no default shortcut; bind `activity.toggle` in Settings → Keybinds. |
| **Command palette** | ⌘K opens a search field over the window with every action, the current session's tabs, sessions and themes. Typing filters with fuzzy matching (word starts and runs rank first); ↑/↓ or ⌃P/⌃N move, ↩ runs, Esc or a click outside closes. The last few picks show first under Recent. Actions show their shortcut; the current tab, session and theme are checked. Moving onto a theme previews it live across the window without saving; Esc or a click outside puts the old one back, and picking it with ↩ writes it to `jelly.toml` (into the matching light or dark slot when the theme follows the system). |
| **Viewer** | ⌘⇧M, or ↩ in the explorer, opens a file over the panes. Markdown is rendered (headings, lists, task lists, tables, quotes, code, images) with a contents menu and working relative links; other text files show with line numbers. Code is syntax-highlighted in the theme's palette colours. It reloads when the file changes on disk. Esc closes it. Terminals behind it keep running. |

## Quick terminal

While Jelly is running, ⌃Space (`quick-terminal.hotkey`) opens a small floating terminal over whatever app you're in, at the bottom centre of the screen under the mouse, without bringing Jelly's windows forward. It looks like the command palette and follows the theme.

- **Your own shell.** It runs your shell (fish, zsh, bash, whatever `shell.program` or your login shell is) exactly as a pane does, starting in your home folder. Prompt, completions, autosuggestions, history and `cd` are all the shell's own. Full-screen programs such as `htop` or `vim` work too.
- **Grows with output.** The panel starts as a single prompt line and grows upward as output arrives, up to 16 rows, then scrolls like any terminal. `clear` (or ⌘K) shrinks it back.
- **Folder badge.** The header shows the shell's current folder, following every `cd`. Long paths show only their last two folders; hover for the full path.
- **Open in Jelly.** ⌘↩ moves the shell, with whatever is running in it, into a new tab of the main window, so you carry on where you were. The next ⌃Space starts a fresh shell.
- **Hiding.** Esc at the prompt, ⌘W, a click outside or the shortcut again hides it; Esc goes to the program when one is running. The shell keeps running while hidden and is still there next time. Typing `exit` ends it; the next ⌃Space starts a new one.
- **Settings → General → Quick Terminal** turns it off or records another shortcut. macOS uses ⌃Space to switch input sources when you have more than one; pick another shortcut if that one is taken.

## Configuration and themes

Everything is plain TOML. A file can hold settings, keybinds, themes, or any mix.

- Your config lives at `~/.config/jelly/jelly.toml` and reloads live when saved.
- **Drop a `.toml` file** onto the window (or **File → Import…**), and Jelly shows what it will change ("adds 2 themes, changes 3 settings"). On confirm, it merges the file into your config.
- Bad config never breaks the app. Jelly keeps the last good values and shows a banner naming the line.

- **Settings window** (⌘,): General, Appearance, Terminal, Keybinds and Updates tabs. Every change is written straight into `jelly.toml` (comments kept) and applies at once. The Appearance tab lists the theme library (built-in themes plus `~/.config/jelly/themes/`) with a preview swatch, and picks one theme or a light/dark pair. The Keybinds tab lists every action by group; click a shortcut and press new keys to rebind it, with reset per action or for all.

Full reference: [config.md](config.md).

## Updates

Jelly updates itself. It checks once a day, shows an **Update available** button in the tab bar next to Find, offers the new version with release notes, and relaunches into your restored sessions. **Jelly → Check for Updates…** checks right away. The first launch after an update opens a What’s New window with that version’s release notes; **Jelly → What’s New…** reopens it.

The very first launch opens a Welcome window before any terminal: the Jelly icon, a line about sessions, and the key features (sessions, split panes, the built-in explorer, the command palette) with their current shortcuts. **Get Started** or closing it opens the first window. **Help → Welcome to Jelly** shows it again.


## Telemetry

Jelly sends anonymous usage data to PostHog so we know how many people use it and on which versions. It is on by default and turned off with **Settings → General → Share anonymous usage data** or `telemetry.enabled = false`.

- `app_launched` on every launch and `app_active` once per day, each with the app version, macOS version, CPU architecture, locale and a random install ID.
- Nothing typed, run or shown in a terminal is sent, and neither are paths, titles, commands or config.
- No person profiles and no GeoIP lookup. Debug builds never send anything.

## Key shortcuts

Every default shortcut is listed in [shortcuts.md](shortcuts.md). All of them can be rebound in Settings → Keybinds or in `[keybinds]`.
