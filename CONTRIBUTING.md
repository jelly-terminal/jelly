# Contributing to Jelly

Thanks for the interest in improving Jelly. This is a small, opinionated codebase — read [`AGENTS.md`](AGENTS.md) before opening a PR, it's the source of truth for how this repo is built and reviewed.

## Before you start

For anything non-trivial, read the relevant doc in `docs/` first:

- [`docs/product.md`](docs/product.md) — what Jelly does and how it looks
- [`docs/tech.md`](docs/tech.md) — architecture, layout, engine, fonts, renderer, testing scope
- [`docs/config.md`](docs/config.md) — `jelly.toml` format and every key
- [`docs/release.md`](docs/release.md) — signing, notarization, Sparkle, CI
- [`docs/roadmap.md`](docs/roadmap.md) — what's in which version

If a change affects behaviour, a config key, or the layout, update the matching doc in the same commit as the code change.

## Setup

Requires Xcode 26+ on macOS 26+. If `xcode-select -p` points at the Command Line Tools, switch it to Xcode first:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

```sh
git clone git@github.com:jelly-terminal/jelly.git
cd jelly
make debug
```

Other targets: `make build`, `make prod`, `make test`, `make kill`, `make clean`.

### Signing

No Apple developer account is needed. `Config/Signing.xcconfig` signs builds ad-hoc ("Sign to Run Locally"), which is enough to run Jelly on your own Mac, from `make` or from Xcode. Ad-hoc signatures change on every build, so macOS may ask again for permissions such as notifications.

To sign with your own team, create `Config/Local.xcconfig`. It is gitignored, so it stays on your machine:

```
DEVELOPMENT_TEAM = YOURTEAMID
CODE_SIGN_IDENTITY = Apple Development
```

Don't set a team under Signing & Capabilities in Xcode: that writes it into `project.pbxproj`. If Xcode raises `objectVersion` in the project file, set Project Format back to Xcode 16.0 in the File inspector so Xcode 26 can still open it.

## Ground rules

- **macOS 26+ only.** No iOS or cross-platform code, no `#available` checks below 26.
- **Swift 6 strict concurrency.** The app target is MainActor by default. `JellyCore` is plain `Sendable` value types. Never block the main thread.
- **Dependency direction:** App → JellyTerminal → JellyCore, never the reverse.
- **One type per file**, grouped in folders by concern. No catch-all `Utils` or `Helpers` files.
- **Glass is chrome only** — never behind terminal text. Sizes and spacing come from `Metrics`, not literals in views.
- **Config never crashes the app.** Invalid values become diagnostics and fall back to defaults.
- **No code comments.** Names should carry the meaning.
- **No new dependencies** beyond SwiftTerm and Sparkle without asking first — open an issue to discuss.
- Nothing is called "stable" before v1.

## Tests

Only test logic that's likely to break and hard to notice by using the app: TOML parsing and in-place editing, config import and diagnostics, colour parsing, the pane split tree, shell launch, font matching and features, query rewriting. Don't test SwiftUI views, rendering, Codable round-trips, defaults, or thin wrappers over Apple APIs. Keep the suite small and fast.

```sh
make test
```

## Commits

- One line, conventional prefix: `feat:`, `fix:`, `perf:`, `refactor:`, `build:`, `docs:`, `test:`, `chore:`.
- Write the subject as a user-readable sentence — it becomes the release note.
- No body, no footer.
- Commit after each completed step rather than bundling unrelated changes.

## Pull requests

- Keep PRs focused on one change. Unrelated cleanup belongs in its own PR.
- Describe what changed and why, and call out any doc updates that go with it.
- Make sure `make build` and `make test` pass before requesting review.
- Screenshots or a short clip are appreciated for anything visual.

## Reporting bugs

Open an issue with macOS version, Jelly version, steps to reproduce, and what you expected instead. For rendering or performance issues, a screen recording of the terminal in action helps a lot.
