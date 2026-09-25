<p align="center">
  <img src="assets/logo.png" width="128" height="128" alt="Jelly icon">
</p>

<h1 align="center">Jelly</h1>

<p align="center">Sweet terminal for the Mac.</p>

<p align="center">
  <a href="https://github.com/jelly-terminal/jelly/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/jelly-terminal/jelly/release.yml?label=release" alt="Release status"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2026%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-6-orange" alt="Swift 6">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/f237ec07-e753-4974-8b5a-ce5cf6317579" width="820" alt="Jelly window">
</p>

> **Early development.** Jelly is a preview. Expect rough edges, and expect config keys and behaviour to change between versions until the stable launch at v1.0.0.

## What is Jelly

Jelly is a terminal made for the Mac. It looks like it belongs on macOS 26, with glass-style windows and smooth, fast text, and it keeps your work tidy so you're never hunting through a pile of windows.

- **Sessions.** Group your work into named spaces like *Work*, *Personal* or *Side project*. Switch between them in one click and every tab and split comes with you. Everything is restored the next time you open Jelly.
- **Tabs and splits.** Split any tab right or down as many times as you like. Drag tabs to reorder them, zoom into one pane, and search through everything a pane has printed.
- **File explorer.** Press ⌘E to see a live file tree of the folder you're working in. It follows you as you move around and updates as files change, which is handy for watching what an AI agent is doing.
- **Agent aware.** Jelly spots Claude Code in your panes, shows whether it's working, needs you, or is done, and sends a notification when it needs you. ⌘⇧A jumps straight to it. Other agents can be switched on in Settings.
- **Built-in previewer.** Press ⌘⇧M to read Markdown files nicely formatted, or any code file with syntax colours, without leaving the terminal. It refreshes when the file changes.
- **Your shell, your way.** Works with the shell, prompt and fonts you already use, including Nerd Fonts, ligatures and emoji.
- **Easy to customise.** Pick a theme, change fonts and rebind any shortcut from Settings (⌘,). Prefer text? Everything lives in one `jelly.toml` file. Drop a theme or config file onto the window to add it.
- **Stays up to date.** Jelly updates itself and shows you what's new after each update.

Full details on every setting are in the [configuration guide](docs/config.md).

## Keyboard shortcuts

| Action | Keys |
|---|---|
| Command palette | ⌘K |
| Split right / down | ⌘D / ⌘⇧D |
| Next / previous tab | ⌘⌥→ / ⌘⌥← |
| Switch session | ⌃⇥ |
| Jump to waiting agent | ⌘⇧A |

See [all shortcuts](docs/shortcuts.md). Every shortcut can be changed in Settings → Keybinds.

## Goals

- **Fast.** GPU-drawn, easy on your battery, smooth even under heavy output.
- **Compatible.** Your shell, prompt and font look the same as in Ghostty or iTerm2.
- **Organized.** Sessions instead of a pile of unnamed windows.
- **Simple to configure.** Settings in the app, or one plain text file.
- **Truly native.** Built for the Mac, not a web page in disguise.

## Install

Jelly isn't distributed outside this repo yet. Build it from source below, or grab a release from [Releases](https://github.com/jelly-terminal/jelly/releases) once one exists.

## Build from source

Requires Xcode 26+ on macOS 26+ and the Metal toolchain (`xcodebuild -downloadComponent MetalToolchain`). No Apple developer account is needed; see [Signing](CONTRIBUTING.md#signing).

```sh
git clone git@github.com:jelly-terminal/jelly.git
cd jelly
make debug   # build Debug and open "Jelly (Debug)"
```

Other targets:

```sh
make build   # build Debug
make prod    # build Release and open
make test    # swift test in both packages
make kill    # stop running Jelly processes
make clean   # remove the derived data directory
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Roadmap

Jelly is in early development. Saved SSH hosts are next, and the stable launch is v1.0.0.

See [docs/roadmap.md](docs/roadmap.md) for everything planned.
