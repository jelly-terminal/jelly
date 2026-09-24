# Jelly: Technical Spec

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 6, strict concurrency, MainActor by default in the app target |
| App shell | AppKit lifecycle (`NSApplicationDelegate`), `NSWindow` hosting SwiftUI |
| Chrome | SwiftUI, Liquid Glass (`.glassEffect`, `GlassEffectContainer`) |
| Terminal | SwiftTerm 1.20 from our fork (`mxvsh/SwiftTerm`, branch `jelly`): its `TerminalView` with the Metal renderer on, subclassed by our `TerminalSurface` |
| PTY | SwiftTerm's `LocalProcess` (`forkpty`), owned by the `jelly-mux` helper so shells outlive the app, or by the app itself as a fallback |
| Config | TOML via our own parser in `JellyCore/TOML` (line numbers, comment-preserving edits), `~/.config/jelly/jelly.toml` |
| Persistence | JSON in `~/Library/Application Support/<bundle id>/` (v0.2) |
| Updates | Sparkle 2 (SPM), EdDSA-signed appcast on GitHub Releases |
| Release | GitHub Actions, Developer ID, notarized DMG ([release.md](release.md)) |
| Minimum OS | macOS 26.0 |

### Why SwiftTerm's view instead of our own renderer

SwiftTerm ships a Metal renderer (glyph atlases, CoreText run shaping, built-in box drawing and powerline, frame recovery) together with selection, IME, mouse modes, kitty keyboard, BiDi, find and accessibility. Rebuilding that would take weeks before Jelly types a character. Everything Jelly-specific sits in `TerminalSurface`, so a custom renderer can replace it later without touching the app.

### Project settings

- Deployment target **macOS 26.0**, Swift 6.
- **No App Sandbox.** A terminal has to spawn the user's shell with full access to their files. Hardened runtime stays on for notarization.
- Debug build: bundle ID `com.monawwar.Jelly.Debug`, display name "Jelly (Debug)", so it never collides with an installed release.
- The fork carries one fix on top of upstream 1.20.0: a line feed onto an existing row clears its soft-wrap flag, as in xterm.js. Without it, programs that redraw in place (Claude Code) get their lines glued together when a pane narrows and then widens. Drop the fork once upstream has the fix.
- SwiftTerm uses a build-tool plugin: Xcode asks to trust it once; command-line builds pass `-skipPackagePluginValidation`.
- The Metal toolchain is a separate Xcode component: `xcodebuild -downloadComponent MetalToolchain`.

## Project layout

```
Jelly/                         App target (file-system synchronized group)
  App/                         Main, AppDelegate, MainMenu, MainWindowController
  Config/                      ConfigStore (loaded config, watcher, appearance, font zoom)
  Features/
    Root/                      RootView, WindowModel, WindowBackground
    Workspace/                 SessionModel, WorkspaceModel (tabs), TabModel (pane tree), PaneModel, ActionHandler
    Panes/                     PaneArea (cards, headers, dividers), PaneLayout, PaneHeader
    Sidebar/                   Sidebar (Sessions), SidebarToggle
    Agents/                    AgentMonitor (1s poll per window), AgentTracker (per pane), AgentNotifier (UserNotifications), AgentPresence (labels), AgentTone, AgentIndicator, AgentPaletteSource
    Explorer/                  ExplorerPanel, ExplorerModel (lazy tree, watchers), DirectoryLister (off main)
    Viewer/                    ViewerCard, ViewerModel (history, links, live reload), ViewerLoader (off main), TextFileView
    Markdown/                  MarkdownView and one view per block kind, MarkdownStyle (theme colours, inline and code highlighting)
    Tabs/                      TabBar
    Palette/                   PaletteModel (query, ranking, recents), PaletteView, PaletteRow, PaletteSource and the PaletteSources list
    Terminal/                  TerminalHost (NSViewRepresentable positioning surfaces)
    StatusBar/
    Diagnostics/               Config problem banner
    Import/                    PendingImport, ImportSheet, ConfigImportService
    Updates/                   UpdaterService (Sparkle), What's New window
    Settings/                  SettingsWindowController (toolbar tabs), one view per tab, ShortcutRecorder
  Shared/                      Metrics, AppInfo, KeyChord+Event, ThemeColor+SwiftUI, FileWatcher
  Resources/                   Assets.xcassets
Packages/
  JellyCore/                   No UI. Plain Sendable value types.
    Sources/JellyCore/
      TOML/                    Parser, Writer, Editor (in-place, comment-preserving)
      Config/                  Settings, decoders, Loader, Importer, Watcher, Diagnostics
      Keybinds/                KeyChord, KeyAction, KeyActionCatalog (names, titles, groups), Keybinds, KeybindEditor
      Theme/                   Theme, ThemeColor, ThemeDecoder, BuiltinThemes
      Workspace/               PaneTree, WorkspaceSnapshot, SnapshotStore
      Markdown/                MarkdownParser (CommonMark + GFM blocks), MarkdownDocument (blocks, outline, anchors)
      Agents/                  AgentProvider, ClaudeCodeAgent (session status file), CommandAgent, AgentCatalog (built-ins + config), ProcessIdentity, TerminalActivity, AgentState
      Palette/                 FuzzyMatcher (subsequence scoring with matched positions)
      Syntax/                  SyntaxHighlighter (byte scanner), SyntaxLanguage (rule tables and aliases), SyntaxToken
      Resources/Themes/        Built-in themes (*.toml)
    Tests/JellyCoreTests/
  JellyTerminal/               Everything that touches SwiftTerm
    Sources/JellyTerminal/
      Surface/                 TerminalSurface, QueryResponder, NSColor+ThemeColor
      Process/                 PaneProcess (what a surface talks to), LocalPaneProcess (in-app PTY)
      Mux/                     Session keep-alive: Protocol/ (frames, socket, channel), Helper/ (MuxServer, MuxHost, MuxSession), Snapshot/ (HeadlessScreen, ScreenSnapshot, TerminalModes), Client/ (MuxClient, MuxPaneProcess)
      Alerts/                  NotificationScanner (OSC 9 / 777 in the output stream)
      Shell/                   ShellLaunch (program, argv0, environment, directory, dropped variables), ProcessArguments (KERN_PROCARGS2), ForegroundProcess
      Font/                    FontResolver, FontFeatures
    Tests/JellyTerminalTests/
Config/
  Jelly-Info.plist             Sparkle keys
docs/
scripts/release-notes.sh
.github/workflows/release.yml
Makefile
```

Dependency direction: **App → JellyTerminal → JellyCore**. Only `JellyTerminal` imports SwiftTerm; the app never does.

## Architecture

```
 keyDown ─▶ local event monitor ─▶ KeyChord ─▶ Keybinds ─▶ ActionHandler (tabs, find, font, config)
                 │ not bound
                 ▼
 TerminalSurface (SwiftTerm view) ─▶ PaneProcess ─▶ jelly-mux (Unix socket) ─▶ PTY ─▶ shell
        ▲                                   │ read queue
        │ feed on main                      ▼
        └──────────────── bytes ◀── PTY output (also fed to a headless terminal in jelly-mux)
        │
        ├─▶ Metal renderer (display-driven, dirty rows only)
        └─▶ callbacks: title, cwd (OSC 7), grid size ─▶ TabModel ─▶ SwiftUI chrome
```

- **Workspace model.** `WindowModel` → `[SessionModel]` → `WorkspaceModel` → `[TabModel]` → `[PaneModel]`. A tab holds a `PaneTree` layout, its panes (each owning one `TerminalSurface`), the focused pane and an optional zoomed pane. All surfaces stay alive; a restored session starts its shells only when first opened. A pane whose shell exits closes itself; the last pane closes the tab.
- **Pane layout.** `PaneLayout` turns the tree into card frames (with `Metrics.paneGap` between them) and divider handles. `PaneArea` draws it in three layers from the same layout: card fills, then `TerminalHost` (one AppKit container holding every surface, placing the selected tab's surfaces inside their cards and hiding the rest), then headers, borders and divider handles. The container only takes hits inside card bodies, so SwiftUI handles headers and dividers. It watches the window's first responder to report which pane was clicked.
- **Chrome vs. content.** Terminal output never touches SwiftUI state. Only title, cwd and grid-size callbacks reach `TabModel`; agent state is polled once a second.
- **Explorer and viewer.** The explorer follows the focused pane's directory, read from its shell with `proc_pidinfo` once a second while the panel is open. Directory listing, file reading, Markdown parsing and highlighting all run off the main thread; each expanded folder and the open file have a `DispatchSource` watcher, debounced and re-armed after atomic saves. The viewer covers the pane area. While it's open, `TerminalHost` gets no cards, so the surfaces are hidden but stay attached and keep running. Copy and paste go to the terminal only when a surface is first responder; otherwise they go down the responder chain, so viewer text can be copied.
- **Command palette.** Each feature adds its items through a `PaletteSource` kept in its own folder (`ActionPaletteSource` in Workspace, `TabPaletteSource` in Tabs, `SessionPaletteSource` in Sidebar, `ThemePaletteSource` in Settings). `PaletteSources.all` sets which sources appear and in what order. Items are built fresh each time the palette opens, so nothing needs to be kept in sync. Actions come from `KeyAction.catalog`, so any new bindable action appears on its own. While the palette is open, the window's key monitor sends arrows, ↩ and Esc to it first; any other bound shortcut closes it and runs, except copy, paste and `text:` bindings, which go to the search field. An item can also offer a `preview` that returns its own undo: the model calls it when the item is selected and undoes it when the selection moves or the palette closes; running the item keeps the preview in place until `perform` has run. Themes preview through `ConfigStore.previewTheme`, which `ConfigStore.theme` prefers and which is never written to disk. An item runs after the palette has closed and focus is back on the terminal, so actions that move focus (explorer, viewer) keep it.
- **Agents.** Once a second, `AgentMonitor` walks the window's panes. A pane whose foreground process group (`tcgetpgrp`) isn't the shell has its leader's arguments read with `sysctl(KERN_PROCARGS2)` and matched against `AgentCatalog` (built-ins in `agents.watch`, plus custom ones); a pane matched once keeps its agent until the group changes. The state comes from the provider when it can report it: `ClaudeCodeAgent` reads `~/.claude/sessions/<pid>.json` (or `$CLAUDE_CONFIG_DIR/sessions`, taken from the agent process's own environment so wrappers that set it work), which Claude Code keeps up to date for its own process: `status` `busy` → working, `waiting` (with `waitingFor`, e.g. "permission prompt") → needs input, `idle` → done. Otherwise `AgentState.guessed` uses the pane's `TerminalActivity`: a bell or OSC 9 / 777 notification (read by `NotificationScanner` from each output chunk, without touching SwiftTerm's own OSC handling) after the last input means it needs you, no output or typing for `agents.idle-after` means done. Nothing here notifies SwiftUI; `PaneModel.agent` changes only when the state does, and `isAgentFinishedUnseen` is set when an agent goes from working to idle while you aren't looking at the pane and cleared on the first tick you are. `AgentTone` (working, attention, finished, ready) is what the chrome draws, summarised per tab and session with attention first; which is all the tab, header, sidebar and status bar read. A change to needs-input (or working → done) posts a notification through `AgentNotifier` unless you're looking at the pane; going back to working withdraws it. To add an agent, conform a type to `AgentProvider` (`id`, `name`, `matches(ProcessIdentity)`, and optionally `state(of:pid:)`) and list it in `AgentCatalog.builtIn`; a plain command-name match is a `CommandAgent`. Shells don't inherit a parent Claude Code session's markers (`CLAUDECODE`, `CLAUDE_CODE_CHILD_SESSION`, …), so `claude` in a pane always runs as its own session.
- **Syntax highlighting.** It uses its own lexer in `JellyCore`, with no dependency: a byte scanner driven by per-language tables (comments, strings, keywords, literals, capitalised types, calls, shell variables, tags, diff lines). Colours come from the theme's ANSI palette, so code matches the terminal.
- **Config.** `ConfigStore` loads and watches the config, tracks light/dark appearance, and notifies each window, which re-applies settings and theme to its surfaces.

## Terminal

SwiftTerm handles VT parsing and rendering. What it supports and we rely on:

- xterm-256color and 24-bit true color, SGR incl. underline styles and colors
- Alternate screen, scroll regions, DECSET modes, bracketed paste, focus events, synchronized output (2026)
- Mouse: X10, normal, button, any-event, SGR (1006); alternate scroll (1007)
- **Kitty keyboard protocol**, OSC 0/2 title, **OSC 7** cwd, OSC 8 hyperlinks, OSC 52 clipboard, **OSC 133** prompt marks

### Selection during output

SwiftTerm drops the selection on every chunk of output while `allowMouseReporting` is on, which is its default, so a spinner redrawing made text impossible to copy. `TerminalSurface` turns `allowMouseReporting` on only while the program has asked for mouse events (`terminal.mouseMode != .off`). Nothing else changes, since SwiftTerm checks the mouse mode before reporting anyway. The selection now stays while a program writes, unless the program has taken over the mouse.

### Query responses

Modern shells ask the terminal about itself at startup and wait for an answer; fish 4 stalls and warns if Device Attributes goes unanswered. SwiftTerm answers DA1, DA2, DECRQM, DSR, kitty keyboard flags and OSC 10/11/12/4 colour queries. `QueryResponder` rewrites its XTVERSION reply so programs see `Jelly <version>`.

## Shells

`ShellLaunch` picks what to launch, first match wins:

1. `settings.shell.program` (+ `args`)
2. The account's login shell from `getpwuid(getuid())->pw_shell`
3. `$SHELL`
4. `/bin/zsh`

The shell starts as a login shell (`argv[0]` prefixed with `-`) in the tab's working directory.

Environment: the user's environment is inherited, plus:

| Variable | Value |
|---|---|
| `TERM` | `xterm-256color` (own terminfo `xterm-jelly` later) |
| `COLORTERM` | `truecolor` |
| `TERM_PROGRAM` | `Jelly` |
| `TERM_PROGRAM_VERSION` | marketing version |
| `LANG` | `en_US.UTF-8` if unset |
| `JELLY_PANE` | pane ID, for scripts |

Jelly never injects shell integration scripts in v0.1. fish 4 emits OSC 133 natively, and starship and most prompts emit OSC 7 or can be told to. Optional integration scripts for zsh and bash come later.

Compatibility matrix tested before each release: fish + starship, zsh + oh-my-zsh, zsh + powerlevel10k, bash, nu; nvim, tmux, htop, lazygit, fzf; `vttest`.

## Fonts

- **Any installed font.** `FontResolver` matches family names ignoring case, spaces, hyphens and underscores, so `Fira Code Nerd Font` and `FiraCode Nerd Font` both work. `SF Mono` maps to the system monospaced font. A missing family falls back to SF Mono with a diagnostic.
- **Fallback.** `font.fallback` families go into the font's cascade list, ahead of the system's own fallback.
- **Ligatures and features.** SwiftTerm's Metal renderer shapes each same-style run with CoreText and places each glyph at its source cell, so contextual ligatures (Fira Code, JetBrains Mono) render. `font.features` become OpenType feature settings on the font; `ligatures = false` turns off `calt`, `liga` and `dlig`.
- **Nerd Font icons** come from the primary font or a fallback such as `Symbols Nerd Font Mono`.
- **Box drawing, blocks and powerline** are drawn by SwiftTerm at cell size, so separators and borders have no gaps.
- **Bold and italic** faces are derived by SwiftTerm through `NSFontManager`.

## Scrolling

Scrollback size is `settings.scrollback`. SwiftTerm's scrollbar is hidden: it isn't inside a scroll view, so it never auto-hides and leaves a track on the right edge. Wheel and trackpad scrolling work as usual.

## Liquid Glass

- Glass is chrome only: the selected tab (morphing between tabs with `glassEffectID`), the find button, the config banner, and the import sheet. Tabs share one `GlassEffectContainer`.
- The sidebar and panes are plain cards, not glass: the theme background with a hairline border. The window background is shaded slightly darker so the cards stand apart.
- No glass behind terminal text. The window draws the theme background with `window.background-opacity`, and `window.blur` adds a behind-window `NSVisualEffectView`.
- Sizes and spacing come from one `Metrics` object, never hardcoded in views.
- The tab bar sits in the transparent title bar next to the traffic lights. The window is not movable by default (`isMovable = false`), so the system never grabs drags in the title-bar strip; only the empty tab-bar area and the sidebar header move it (`WindowDragGesture`). Tabs reorder with their own `DragGesture`: during a drag only offsets change, and the tab list is moved once on drop.

## Configuration

See [config.md](config.md) for the format. Internals:

- `ConfigLoader` reads `~/.config/jelly/jelly.toml`, then decodes into `Settings` (typed, with defaults for every key). Unknown or invalid keys produce `Diagnostic`s with a line number instead of errors.
- `ConfigWatcher` uses a `DispatchSource` file-system watch on the file and its directory, so editors that write atomically are still caught. It debounces by 100ms.
- `ConfigImporter` builds an `ImportPlan` (what changes, which themes are new or replaced) for the preview, then applies it with `TOMLEditor`, which edits the source text in place so the user's comments and ordering survive.
- The Settings window never keeps its own copy of settings. Controls read `ConfigStore.config` and write through `TOMLEditor.set` / `remove` (`ConfigStore+Editing`), then reload. Keybind changes go through `KeybindEditor`, which releases a default chord by writing `"none"` and reuses the spelling of keys already in the file. If `jelly.toml` has a syntax error the window shows it and writes nothing.
- `ConfigLoader` loads built-in themes from the `JellyCore` bundle, then `~/.config/jelly/themes/*.toml`. A user theme with the same `id` replaces the built-in one.

## Persistence

`SnapshotStore` writes `workspace.json` in Application Support (per bundle ID, so Debug and release never share it): every open window with its frame, sessions, tabs' split layouts, each pane's working directory, the focused pane and custom titles, the selected session and tab, and sidebar visibility; and which window was frontmost. A file from before multiple windows were saved loads as one window. It's saved every 5 seconds when something changed, when the window closes and on quit, so a crash or force-quit loses at most a few seconds. Launch reopens every saved window and brings the frontmost one forward; a missing or unreadable file opens one fresh window. Closing a window while others stay open forgets it. Closing the last one keeps it, so clicking the Dock icon or relaunching brings it back. A tab's directory is read from its shell process (`proc_pidinfo`), so it's right for any shell, with the OSC 7 value as a fallback. Pane IDs (and so `JELLY_PANE`) survive a relaunch, and each pane reattaches to its running shell by that ID (see [Session keep-alive](#session-keep-alive)). A pane whose shell is gone starts a new one in its last directory.

## Session keep-alive

Shells run in a helper, `jelly-mux`, so they outlive the app. The helper is the Jelly executable itself started with `--mux <socket>` (`MuxServer.runIfRequested()` at the top of `main`), so there is no second target to build or sign. The app starts it with `posix_spawn` and `POSIX_SPAWN_SETSID`, so it keeps running when the app quits or crashes, and Sparkle can replace the bundle under it.

- **Socket.** `$TMPDIR/<bundle id>.mux`, mode 0600, and the helper checks the peer's uid. Debug and release builds have separate helpers.
- **Protocol.** Frames of `[type u8][length u32 LE][payload]`. Control payloads are JSON; input and output are raw bytes. Every connection starts with `hello { version }` both ways. `MuxProtocol.supportedVersions` lists what the app speaks; a helper it can't talk to is left alone and panes fall back to in-app shells. A newer app must keep speaking the versions older helpers use, since a helper started by the previous version is still running after an update.
- **One connection per pane.** `open { pane, launch?, size, scrollback }` attaches to the pane's session or, with a `launch`, starts a new one. The helper answers `opened { pid, restored }` (and, when restored, the screen as `output`) or `missing`. After that the pane sends `input`, `resize` and `terminate`; the helper sends `output` and `exited`. A closed connection just detaches. A second attach to the same pane takes it over.
- **Control connections.** `prune { keep }` ends detached sessions whose pane isn't in the saved workspace; the app sends it after every snapshot save and at launch. `endAll` ends everything (Quit and End Sessions, or quitting with `session.keep-alive = false`).
- **Screen restore.** Each session feeds its output into a `HeadlessScreen`, a SwiftTerm `Terminal` with no view. On reattach it's resized to the pane and `ScreenSnapshot` writes it back as escape sequences: title (OSC 2), directory (OSC 7), every scrollback and screen line with its SGR attributes and soft wraps, the scroll region, DEC and ANSI modes, kitty keyboard flags, the cursor and the current pen. SwiftTerm keeps most modes internal, so they're read with DECRQM queries fed to the headless terminal (after a CAN, so a half-received sequence can't swallow them). SwiftTerm can't read the primary screen while the alternate one is active, so the helper watches the output for `?1049h` / `?1047h` / `?47h` and keeps the primary screen's lines just before the switch; the snapshot writes them, then `?1049h`, then the alternate screen. While no pane is attached, the headless terminal answers the program's queries (DA, DSR, …) itself.
- **Lifetime.** A session ends when its shell exits (the pane gets `exited` and closes) or when it's terminated: SIGHUP to the shell, then the PTY is closed and the shell reaped. The helper exits 5 seconds after its last session ends, removing the socket; the next pane starts a new one.
- **Fallback.** Connecting runs off the main thread; keys typed meanwhile are queued. If the helper can't be started or reached within 3 seconds, or `session.keep-alive` is off, the pane runs its shell in the app through `LocalPaneProcess`. A restored pane still reattaches to a running helper when keep-alive is off.
- **Backpressure.** The helper writes output to the socket on the session's queue, so a pane that isn't reading slows the program down as a PTY would. The app stops reading a pane's socket while more than 4 MB waits to be fed to its view.
- **What stays in the app.** Agent detection reads the foreground process group from the shell's `proc_bsdinfo.e_tpgid` and the directory from `proc_pidinfo`, which work for either kind of shell. Reboot and logout still end every process; the saved layout and directories cover those.

## Updates

Sparkle 2 via SPM, wrapped by `UpdaterService` and owned by `AppDelegate`.

- Standard Sparkle UI in v0.1; a custom glass update sheet (`SPUUserDriver`) later.
- **Jelly → Check for Updates…** menu item; automatic check every 24h.
- Debug builds, and builds without `SUPublicEDKey`, never start the updater.
- `WhatsNewPresenter` remembers the last launched version in `UserDefaults`. When it differs from the running version it fetches the GitHub release body for `v<version>` (`ReleaseNotesLoader`) and shows it with `MarkdownView` in a window. The first ever launch records the version without showing anything, and a failed fetch retries on the next launch.
- `updates.check` and `updates.auto-install` map to Sparkle's automatic check and automatic download.
- Because Jelly isn't sandboxed, Sparkle's sandbox extras (installer launcher service, mach-lookup exceptions) are not needed.

Pipeline and keys: [release.md](release.md).

## Performance budgets

| Metric | Budget |
|---|---|
| Keystroke to pixels | < 5ms at 120Hz |
| Cold start to prompt | < 200ms (excluding shell startup) |
| Idle CPU | 0% with no output and cursor blink off |
| `cat` 100MB file | No dropped frames, > 200MB/s throughput |
| Memory per pane | < 20MB with 10k lines of scrollback |

Measured with Instruments (Time Profiler, Metal System Trace) before each release.

## Testing

Unit tests live in the packages (`swift test`) and only cover logic where a bug is likely and hard to catch by using the app. No UI tests, no snapshot tests, no tests of Codable round-trips, defaults, or wrappers around Apple APIs.

**JellyCore**
- `TOMLParser`: the shapes config files use, and the line number of each kind of error.
- `KeybindEditor` / `TOMLEditor.remove`: removing a line keeps comments, keys inside inline tables, binding releases old chords and reuses written keys, reset restores defaults, catalog names parse back.
- `ConfigImporter`: values replaced in place with comments kept, missing keys added to the right table, inline tables merged, unchanged values skipped, replaced themes flagged, broken configs refused.
- `ConfigDocument`: invalid values fall back and report their line; syntax errors keep defaults; `none` unbinds; themes need 16 valid colors; hex parsing; built-in themes load.
- `FuzzyMatcher`: subsequences ignoring case and spaces, word starts and runs beating scattered letters, camelCase boundaries.
- `ClaudeCodeAgent` / `AgentState` / `AgentCatalog`: Claude session status mapped (and ignored for another pid), guessed state from quiet time and alerts versus input, native binaries and interpreter scripts matched, other programs' arguments ignored, only Claude watched by default, watch list and custom agents from config.
- `PaneTree`: split, close (the sibling takes the parent's place), focus by direction, ratio bounds, equalize.
- `SyntaxHighlighter`: tokens for words, escaped strings and comments; aliases; shell variables and literal single quotes; tokens split per line across multi-line comments and strings; diff lines.
- `MarkdownParser` / `MarkdownDocument`: ATX, setext and rules told apart; soft and hard breaks; fences (longer closers, unclosed); nested lists with tasks, code and lazy lines; quotes with lazy lines; table cells with escaped pipes and code spans; GitHub-style heading anchors.

**JellyTerminal**
- `ShellLaunch`: order of precedence, `-` prefix on `argv[0]`, working directory, environment (Jelly identity, other terminals' and parent Claude Code sessions' variables dropped, user overrides).
- `FontResolver` / `FontFeature`: family matching, feature parsing, ligatures off.
- `QueryResponder`: XTVERSION answers as Jelly, other replies pass through.
- `ScreenSnapshot` / `HeadlessScreen`: scrollback, cursor, soft wraps, colours and underline styles, modes, scroll region, keyboard flags, title and directory survive a round trip; the primary screen comes back after leaving the alternate one; DECRQM replies parse. `MuxFrameReader`: frames split across reads, unknown and oversized frames rejected.
- `NotificationScanner` / `ProcessArguments`: OSC 9 and 777 with BEL or ST, split chunks, progress reports and other codes ignored, oversized and cancelled sequences dropped; `KERN_PROCARGS2` layout.

Rendering, fonts and shells are verified by hand against the compatibility matrix above.
