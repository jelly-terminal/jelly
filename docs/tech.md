# Jelly: Technical Spec

## Stack

| Layer | Choice |
|---|---|
| Language | Swift 6.2, strict concurrency, MainActor by default in the app target |
| App shell | AppKit lifecycle (`NSApplicationDelegate`), `NSWindow` hosting SwiftUI |
| Chrome | SwiftUI, Liquid Glass (`.glassEffect`, `GlassEffectContainer`) |
| Terminal surface | AppKit `NSView` backed by `CAMetalLayer`, our own Metal renderer |
| VT parsing and screen state | SwiftTerm's headless `Terminal`, behind a `TerminalEngine` protocol |
| PTY | `forkpty` + non-blocking read loop, one I/O thread per pane |
| Config | TOML via our own parser in `JellyCore/TOML` (line numbers, comment-preserving edits), `~/.config/jelly/jelly.toml` |
| Persistence | JSON in `~/Library/Application Support/<bundle id>/` |
| Updates | Sparkle 2 (SPM), EdDSA-signed appcast on GitHub Releases |
| Release | GitHub Actions, Developer ID, notarized DMG ([release.md](release.md)) |
| Minimum OS | macOS 26.0 |

### Project settings to change from the Xcode template

- `MACOSX_DEPLOYMENT_TARGET` from 27.0 to **26.0**.
- `SWIFT_VERSION` from 5.0 to **6**.
- `ENABLE_APP_SANDBOX` to **NO**. A terminal has to spawn the user's shell with full access to their files. Hardened runtime stays on, since notarization requires it.
- Remove SwiftData and the template's `Item.swift` / `ContentView.swift`.
- Debug build: bundle ID `com.monawwar.Jelly.Debug`, display name "Jelly Debug", so it never collides with an installed release.

## Project layout

```
Jelly/                         App target (file-system synchronized group)
  App/                         main, AppDelegate, MainMenu, WindowController
  Features/
    Sidebar/                   SidebarView, SessionsSection, ProjectsSection, ConnectSection
    Tabs/                      TabBar, TabItem
    Panes/                     SplitView, PaneHeader, TerminalPaneView (NSViewRepresentable)
    StatusBar/
    Search/
    Import/                    .toml drop / File → Import → preview sheet → merge
    Updates/                   UpdaterService
  Resources/                   Assets.xcassets
Packages/
  JellyCore/                   No UI. Config, themes, models, persistence, split tree
    Sources/JellyCore/
      TOML/                    Parser, Writer, Editor (in-place, comment-preserving)
      Config/                  Settings, decoders, Loader, Importer, Watcher, Diagnostics
      Keybinds/                KeyChord, KeyAction, Keybinds
      Resources/Themes/        Built-in themes (*.toml)
      Theme/                   Theme, ThemeColor, ThemeDecoder, BuiltinThemes
      Workspace/               Session, Tab, PaneTree, Project
      Persistence/             SnapshotStore
    Tests/JellyCoreTests/
  JellyTerminal/               Terminal engine, PTY, input, fonts, renderer
    Sources/JellyTerminal/
      Engine/                  TerminalEngine protocol, SwiftTermEngine, QueryResponder
      PTY/                     PTYProcess, ShellResolver, Environment
      Input/                   KeyEncoder, MouseEncoder, KittyKeyboard
      Font/                    FontResolver, FontFallback, CellMetrics, UnicodeWidth
      Renderer/                MetalRenderer, GlyphAtlas, BoxDrawing, Shaders.metal
      View/                    TerminalView (NSView), SelectionController
    Tests/JellyTerminalTests/
Config/
  Jelly-Info.plist             Sparkle keys
  Jelly.entitlements
docs/
scripts/release-notes.sh
.github/workflows/release.yml
Makefile
```

Both packages use `swift-tools-version: 6.2`, `platforms: [.macOS("26.0")]`. Neither uses default MainActor isolation: `JellyCore` is `Sendable` value types shared with the terminal thread, and PTY I/O and parsing in `JellyTerminal` run off the main actor.

Dependency direction: **App → JellyTerminal → JellyCore**. Nothing in the packages imports SwiftUI except `JellyTerminal/View`, which needs only AppKit.

## Architecture

```
            ┌──────────── main actor ────────────┐
 keyboard → │ TerminalView ─ KeyEncoder ─┐        │
            │                             ▼        │
            │ SwiftUI chrome ◂── throttled ── PaneModel (title, cwd, size)
            └────────────────────────────┼────────┘
                                         │ bytes
            ┌──── pane I/O thread ───────▼────────┐
            │ PTYProcess ⇄ shell                  │
            │   read → TerminalEngine.feed(bytes) │
            │   engine → QueryResponder → PTY     │
            │   marks rows dirty                  │
            └────────────────┬────────────────────┘
                             │ dirty flag
            ┌──── display link ▼──────────────────┐
            │ MetalRenderer: snapshot dirty rows, │
            │ shape runs, atlas lookup, 1 draw    │
            └─────────────────────────────────────┘
```

- **Workspace model.** `Session` → `[Tab]` → `PaneTree` (a binary split tree whose leaves are `PaneID`s). Each leaf maps to a live `TerminalPane` (engine + PTY + view). The tree is a value type in `JellyCore`, so layout logic is testable without a terminal.
- **Chrome vs. content.** Terminal output never changes observable SwiftUI state directly. `PaneModel` publishes title, cwd and grid size at most every 100ms, so heavy output can't cause SwiftUI re-renders.

## Terminal engine

`TerminalEngine` is our protocol: `feed(_ bytes:)`, `resize(cols:rows:)`, snapshot of visible rows, cursor, modes, scrollback access, and callbacks for title, cwd, bell, clipboard and responses. The first implementation wraps SwiftTerm's headless `Terminal`. If profiling shows the parser is the bottleneck, libghostty-vt can replace it behind the same protocol.

### Protocols supported

- xterm-256color and 24-bit true color, SGR incl. underline styles and colors
- Alternate screen, scroll regions, DECSET modes, bracketed paste, focus events
- Mouse: X10, normal, button, any-event, SGR (1006)
- **Kitty keyboard protocol** (`CSI u`, progressive enhancement flags)
- OSC 0/2 title, **OSC 7** cwd, OSC 8 hyperlinks, OSC 52 clipboard (write only by default), **OSC 133** prompt marks, OSC 4/10/11/12 color queries
- Synchronized output (mode 2026), so full-screen TUIs don't tear

### Query responses

Modern shells ask the terminal about itself at startup and wait for an answer. fish 4 in particular stalls and warns if Device Attributes goes unanswered. `QueryResponder` answers:

| Query | Response |
|---|---|
| DA1 `CSI c` | VT220 with the features we implement |
| DA2 `CSI > c` | Jelly's ID and version |
| XTVERSION `CSI > q` | `Jelly <version>` |
| DECRQM `CSI ? Pm $ p` | Real state of each mode |
| Kitty keyboard `CSI ? u` | Current flags |
| OSC 10/11/12/4 `?` | Theme foreground, background, cursor, palette |
| DSR `CSI 6 n` | Cursor position |

## Shells

`ShellResolver` picks what to launch, first match wins:

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
| `JELLY_SESSION` / `JELLY_PANE` | IDs, for scripts |

Jelly never injects shell integration scripts in v0.1. fish 4 emits OSC 133 natively, and starship and most prompts emit OSC 7 or can be told to. Optional integration scripts for zsh and bash come later.

Compatibility matrix tested before each release: fish + starship, zsh + oh-my-zsh, zsh + powerlevel10k, bash, nu; nvim, tmux, htop, lazygit, fzf; `vttest`.

## Fonts

- **Any installed font.** Family names are matched ignoring case, spaces and hyphens, so `Fira Code Nerd Font` and `FiraCode Nerd Font` both work. The picker lists every fixed-pitch family CoreText knows. TTF, OTF, TTC and variable fonts are supported.
- **Faces.** Bold, italic and bold-italic come from the family. If a face is missing, it's synthesized (stroke for bold, skew for italic).
- **Fallback chain**, cached per codepoint and style:
  1. `font.fallback` list
  2. `CTFontCopyDefaultCascadeListForLanguages`
  3. `CTFontCreateForString`
- **Nerd Font icons** (Private Use Area) come from the primary font or a fallback such as `Symbols Nerd Font Mono`. Icons followed by a space may render 2 cells wide, as Nerd Font's "Mono" variants expect.
- **Box drawing, blocks, braille, powerline** (U+2500–259F, U+2800–28FF, U+E0B0–E0D4) are drawn by `BoxDrawing` at cell size. Font versions of these leave hairline gaps between cells.
- **Ligatures.** Runs of cells with the same style are shaped with CoreText (`CTLine`) and the result is cached per run. Configurable OpenType features (`calt`, `liga`, `ss01`, `zero`…).
- **Width.** Unicode 16 East Asian Width + emoji presentation tables, grapheme clusters (ZWJ, flags, skin tones, VS16).
- **Cell metrics** come from the font's advance width, ascent, descent and leading, rounded to device pixels, with `cell-width` / `cell-height` adjustments. They're recomputed on font, size or backing scale change.

## Renderer

- `CAMetalLayer` per pane, driven by `NSView.displayLink(target:selector:)`. A frame is only drawn when the engine marked rows dirty or the cursor blinked. Idle panes cost nothing.
- **Glyph atlases:** one grayscale (text) and one BGRA (color emoji), packed with a shelf allocator, rasterized with CoreText at backing scale. Glyphs are keyed by font, glyph ID, and subpixel variant.
- **One draw call per pane:** background cells, glyphs, decorations (underline, strikethrough), cursor and selection as instanced quads from one per-frame buffer. Triple-buffered with a semaphore.
- Only dirty rows are re-shaped and re-uploaded.
- Colors in linear space. Gamma-correct blending keeps text weight consistent on light and dark themes.
- Selection, search highlights and the cursor are overlay passes, so they don't invalidate row caches.

## PTY and I/O

- One thread per pane runs a `read` loop into a 64KB buffer. The engine is fed there, and all engine access is serialized on that thread.
- The renderer takes a row snapshot under a short lock, so the main thread never waits on parsing.
- Writes (input, query responses) go through a single write queue per pane.
- Child exit is detected with `DispatchSource.makeProcessSource`. The pane shows "[process exited]" or closes, depending on settings.
- Resize: `TIOCSWINSZ` + engine resize, debounced during live window resizing.

## Scrollback

Ring buffer of packed rows (cell = codepoint/grapheme index, fg, bg, attrs), limit from `settings.scrollback`. Rows get compacted when they leave the visible screen.

## Liquid Glass

- Glass is chrome only: sidebar (`NavigationSplitView` sidebar), tab bar, pane headers, status bar, search field, import sheet. Neighbouring glass shapes share a `GlassEffectContainer`.
- No glass behind terminal text. The terminal draws its theme background with `window.background-opacity` and optional `window.blur` (via `NSVisualEffectView` behind the Metal layer).
- Sizes and spacing come from one `Metrics` object, never hardcoded in views.
- Tab and pane changes animate with `glassEffectID` / `matchedGeometryEffect`.

## Configuration

See [config.md](config.md) for the format. Internals:

- `ConfigLoader` reads `~/.config/jelly/jelly.toml`, then decodes into `Settings` (typed, with defaults for every key). Unknown or invalid keys produce `Diagnostic`s with a line number instead of errors.
- `ConfigWatcher` uses a `DispatchSource` file-system watch on the file and its directory, so editors that write atomically are still caught. It debounces by 100ms.
- `ConfigImporter` builds an `ImportPlan` (what changes, which themes are new or replaced) for the preview, then applies it with `TOMLEditor`, which edits the source text in place so the user's comments and ordering survive.
- `ConfigLoader` loads built-in themes from the `JellyCore` bundle, then `~/.config/jelly/themes/*.toml`. A user theme with the same `id` replaces the built-in one.

## Persistence

`SnapshotStore` writes `sessions.json`: sessions, tabs, pane trees, each pane's last cwd and title, sidebar state and window frame. It's written 1s after changes and on quit. Running processes are not restored; each pane restarts its shell in its last cwd.

## Updates

Sparkle 2 via SPM, wrapped by `UpdaterService` and owned by `AppDelegate`.

- Standard Sparkle UI in v0.1; a custom glass update sheet (`SPUUserDriver`) later.
- **Jelly → Check for Updates…** menu item; automatic check every 24h.
- Before an update relaunches the app, `SnapshotStore` saves, so sessions come back.
- Debug builds never start the updater.
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
- `ConfigImporter`: settings merged key by key, themes upserted by `id`, the user's comments kept, tables that don't exist yet created.
- `ConfigLoader`: an invalid value produces a diagnostic with the right line and falls back to the default, while the rest of the file still loads.
- `Color`: hex parsing (`#rgb`, `#rrggbb`, `#rrggbbaa`) and rejection of bad input; a theme palette must have 16 entries.
- `PaneTree`: split, close (the sibling takes the parent's place), focus by direction, and resize ratios kept within bounds.

**JellyTerminal**
- `KeyEncoder`: Enter vs Shift+Enter, Alt as Esc prefix, arrows in normal vs application cursor mode, kitty keyboard encodings for ambiguous keys (Ctrl+I vs Tab).
- `QueryResponder`: DA1, DA2, XTVERSION, OSC 11 and DECRQM each produce the exact expected bytes. A missing reply is what makes fish stall.
- `UnicodeWidth`: CJK, emoji ZWJ sequences, flags, VS16, Nerd Font icons.
- `ShellResolver`: order of precedence, and the `-` prefix on `argv[0]`.
- `FontResolver`: family name matching ignoring case, spaces and hyphens.

Rendering and fonts are verified by hand against the compatibility matrix above.
