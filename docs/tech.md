# Jelly: Technical Spec

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 6, strict concurrency, MainActor by default in the app target |
| App shell | AppKit lifecycle (`NSApplicationDelegate`), `NSWindow` hosting SwiftUI |
| Chrome | SwiftUI, Liquid Glass (`.glassEffect`, `GlassEffectContainer`) |
| Terminal | SwiftTerm 1.20+: its `LocalProcessTerminalView` with the Metal renderer on, wrapped by our `TerminalSurface` |
| PTY | SwiftTerm's `LocalProcess` (`openpty` + `login_tty`), reads on a background queue, feeds on main |
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
- SwiftTerm uses a build-tool plugin: Xcode asks to trust it once; command-line builds pass `-skipPackagePluginValidation`.
- The Metal toolchain is a separate Xcode component: `xcodebuild -downloadComponent MetalToolchain`.

## Project layout

```
Jelly/                         App target (file-system synchronized group)
  App/                         Main, AppDelegate, MainMenu, MainWindowController
  Config/                      ConfigStore (loaded config, watcher, appearance, font zoom)
  Features/
    Root/                      RootView, WindowModel, WindowBackground
    Workspace/                 SessionModel, WorkspaceModel (tabs), TabModel (pane tree), PaneModel, ProjectStore, ActionHandler
    Panes/                     PaneArea (cards, headers, dividers), PaneLayout, PaneHeader
    Sidebar/                   Sidebar (Sessions, Projects), SidebarToggle
    Tabs/                      TabBar
    Terminal/                  TerminalHost (NSViewRepresentable positioning surfaces)
    StatusBar/
    Diagnostics/               Config problem banner
    Import/                    PendingImport, ImportSheet, ConfigImportService
    Updates/                   UpdaterService (Sparkle)
    Settings/                  SettingsWindowController (toolbar tabs), one view per tab, ShortcutRecorder
  Shared/                      Metrics, AppInfo, KeyChord+Event, ThemeColor+SwiftUI
  Resources/                   Assets.xcassets
Packages/
  JellyCore/                   No UI. Plain Sendable value types.
    Sources/JellyCore/
      TOML/                    Parser, Writer, Editor (in-place, comment-preserving)
      Config/                  Settings, decoders, Loader, Importer, Watcher, Diagnostics
      Keybinds/                KeyChord, KeyAction, KeyActionCatalog (names, titles, groups), Keybinds, KeybindEditor
      Theme/                   Theme, ThemeColor, ThemeDecoder, BuiltinThemes
      Workspace/               PaneTree, WorkspaceSnapshot, SnapshotStore
      Resources/Themes/        Built-in themes (*.toml)
    Tests/JellyCoreTests/
  JellyTerminal/               Everything that touches SwiftTerm
    Sources/JellyTerminal/
      Surface/                 TerminalSurface, QueryResponder, NSColor+ThemeColor
      Shell/                   ShellLaunch (program, argv0, environment, directory)
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
 TerminalSurface (SwiftTerm view) ─▶ LocalProcess ─▶ PTY ─▶ shell
        ▲                                   │ read queue
        │ feed on main                      ▼
        └──────────────── bytes ◀── PTY output
        │
        ├─▶ Metal renderer (display-driven, dirty rows only)
        └─▶ callbacks: title, cwd (OSC 7), grid size ─▶ TabModel ─▶ SwiftUI chrome
```

- **Workspace model.** `WindowModel` → `[SessionModel]` → `WorkspaceModel` → `[TabModel]` → `[PaneModel]`. A tab holds a `PaneTree` layout, its panes (each owning one `TerminalSurface`), the focused pane and an optional zoomed pane. All surfaces stay alive; a restored session starts its shells only when first opened. A pane whose shell exits closes itself; the last pane closes the tab.
- **Pane layout.** `PaneLayout` turns the tree into card frames (with `Metrics.paneGap` between them) and divider handles. `PaneArea` draws it in three layers from the same layout: card fills, then `TerminalHost` (one AppKit container holding every surface, placing the selected tab's surfaces inside their cards and hiding the rest), then headers, borders and divider handles. The container only takes hits inside card bodies, so SwiftUI handles headers and dividers. It watches the window's first responder to report which pane was clicked.
- **Chrome vs. content.** Terminal output never touches SwiftUI state. Only title, cwd and grid-size callbacks reach `TabModel`.
- **Config.** `ConfigStore` loads and watches the config, tracks light/dark appearance, and notifies each window, which re-applies settings and theme to its surfaces.

## Terminal

SwiftTerm handles VT parsing and rendering. What it supports and we rely on:

- xterm-256color and 24-bit true color, SGR incl. underline styles and colors
- Alternate screen, scroll regions, DECSET modes, bracketed paste, focus events, synchronized output (2026)
- Mouse: X10, normal, button, any-event, SGR (1006); alternate scroll (1007)
- **Kitty keyboard protocol**, OSC 0/2 title, **OSC 7** cwd, OSC 8 hyperlinks, OSC 52 clipboard, **OSC 133** prompt marks

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
- The tab bar sits in the transparent title bar next to the traffic lights and drags the window (`WindowDragGesture`).

## Configuration

See [config.md](config.md) for the format. Internals:

- `ConfigLoader` reads `~/.config/jelly/jelly.toml`, then decodes into `Settings` (typed, with defaults for every key). Unknown or invalid keys produce `Diagnostic`s with a line number instead of errors.
- `ConfigWatcher` uses a `DispatchSource` file-system watch on the file and its directory, so editors that write atomically are still caught. It debounces by 100ms.
- `ConfigImporter` builds an `ImportPlan` (what changes, which themes are new or replaced) for the preview, then applies it with `TOMLEditor`, which edits the source text in place so the user's comments and ordering survive.
- The Settings window never keeps its own copy of settings. Controls read `ConfigStore.config` and write through `TOMLEditor.set` / `remove` (`ConfigStore+Editing`), then reload. Keybind changes go through `KeybindEditor`, which releases a default chord by writing `"none"` and reuses the spelling of keys already in the file. If `jelly.toml` has a syntax error the window shows it and writes nothing.
- `ConfigLoader` loads built-in themes from the `JellyCore` bundle, then `~/.config/jelly/themes/*.toml`. A user theme with the same `id` replaces the built-in one.

## Persistence

`SnapshotStore` writes `workspace.json` in Application Support (per bundle ID, so Debug and release never share it): sessions with their tabs' split layouts, each pane's working directory, the focused pane and custom titles, the selected session and tab, projects, and sidebar visibility. It's saved every 5 seconds when something changed, when the window closes and on quit, so a crash or force-quit loses at most a few seconds. The first window restores it. A tab's directory is read from its shell process (`proc_pidinfo`), so it's right for any shell, with the OSC 7 value as a fallback. Pane IDs (and so `JELLY_PANE`) survive a relaunch. Running processes are not restored; each pane starts its shell in its last directory.

## Updates

Sparkle 2 via SPM, wrapped by `UpdaterService` and owned by `AppDelegate`.

- Standard Sparkle UI in v0.1; a custom glass update sheet (`SPUUserDriver`) later.
- **Jelly → Check for Updates…** menu item; automatic check every 24h.
- Debug builds, and builds without `SUPublicEDKey`, never start the updater.
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
- `PaneTree`: split, close (the sibling takes the parent's place), focus by direction, ratio bounds, equalize.

**JellyTerminal**
- `ShellLaunch`: order of precedence, `-` prefix on `argv[0]`, working directory, environment (Jelly identity, other terminals' variables dropped, user overrides).
- `FontResolver` / `FontFeature`: family matching, feature parsing, ligatures off.
- `QueryResponder`: XTVERSION answers as Jelly, other replies pass through.

Rendering, fonts and shells are verified by hand against the compatibility matrix above.
