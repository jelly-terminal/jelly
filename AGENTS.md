# AGENTS.md

Jelly is a native macOS 26+ terminal: SwiftUI + AppKit chrome with Liquid Glass, SwiftTerm's Metal-rendered terminal view wrapped in `TerminalSurface`, TOML config, Sparkle updates. Read `docs/` before changing anything non-trivial:

- `docs/product.md`: what Jelly does and how it looks
- `docs/tech.md`: architecture, layout, engine, fonts, renderer, testing scope
- `docs/config.md`: `jelly.toml` format and every key
- `docs/release.md`: signing, notarization, Sparkle, CI
- `docs/roadmap.md`: what's in which version

Keep the docs in step with the code. A change to behaviour, a config key or the layout updates the matching doc in the same commit.

## Layout

```
Jelly/                 App target: App/, Features/<Feature>/, Resources/
Packages/JellyCore/    Config, themes, workspace model, persistence. No UI.
Packages/JellyTerminal/ TerminalSurface (SwiftTerm), shell launch, fonts. Only place that imports SwiftTerm.
Config/                Info.plist extras (Sparkle), entitlements
docs/
```

- Dependency direction: App → JellyTerminal → JellyCore. Never the reverse.
- One type per file, grouped in folders by concern. No catch-all `Utils` or `Helpers` files.
- The app folder is a file-system synchronized group: new files are picked up automatically, don't add them to `project.pbxproj`.

## Rules

- **macOS 26+ only.** No iOS or cross-platform code, no `#available` checks below 26.
- **Swift 6 strict concurrency.** The app target is MainActor by default. `JellyCore` is plain `Sendable` value types (only `ConfigWatcher` is `@MainActor`). Never block the main thread: terminal output is fed on main by SwiftTerm, so nothing else heavy may run there.
- **Terminal output never drives SwiftUI directly.** Only title, cwd and grid-size callbacks reach `TabModel`.
- **Glass is chrome only.** Never put `.glassEffect` behind terminal text. Sizes and spacing come from `Metrics`, not literals in views.
- **Not sandboxed.** Hardened runtime stays on.
- **Config never crashes the app.** Invalid values become diagnostics and fall back to defaults.
- **No code comments.** Names should carry the meaning.
- **No new dependencies** beyond SwiftTerm and Sparkle without asking. TOML is parsed by our own `JellyCore/TOML`.
- Nothing is called "stable" before v1.

## Build and test

```sh
make build      # build Debug
make debug      # build Debug and open "Jelly Debug"
make prod       # build Release and open
make test       # swift test in both packages
make kill
make clean
```

Build from a shell with a scratch `-derivedDataPath`. Launch with `open`, then ask the user to check the UI; don't drive the mouse or menus.

## Tests

Only test logic that is likely to break and hard to notice by using the app: TOML parsing and in-place editing, config import and diagnostics, colour parsing, the pane split tree, shell launch, font matching and features, query rewriting. Don't test SwiftUI views, rendering, Codable round-trips, defaults, or thin wrappers over Apple APIs. Keep the suite small and fast.

## Commits

- Commit after each completed step.
- One line, conventional prefix: `feat:`, `fix:`, `perf:`, `refactor:`, `build:`, `docs:`, `test:`, `chore:`.
- Write the subject as a user-readable sentence; it becomes the release note.
- No body, no footer, no co-author or tool attribution lines.
