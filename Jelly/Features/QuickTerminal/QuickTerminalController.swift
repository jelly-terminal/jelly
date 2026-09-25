import AppKit
import JellyCore
import JellyTerminal
import SwiftUI

final class QuickTerminalController: NSObject, NSWindowDelegate {
    let model: QuickTerminalModel

    private let configStore: ConfigStore
    private var panel: QuickTerminalPanel?
    private var hotKey: GlobalHotKey?
    private var hotKeyChord: KeyChord?
    private var monitor: Any?
    private var directoryTimer: Timer?
    private var contentHeight: CGFloat = 0
    private weak var previousKeyWindow: NSWindow?

    init(configStore: ConfigStore, onOpenInTab: @escaping (TerminalSurface) -> Void) {
        self.configStore = configStore
        model = QuickTerminalModel(configStore: configStore)
        super.init()
        model.onOpenInTab = { [weak self] surface in
            self?.hide()
            onOpenInTab(surface)
        }
        model.onContentHeightChange = { [weak self] height in self?.resize(to: height) }
        model.onShellExit = { [weak self] in self?.hide() }
        _ = configStore.observe { [weak self] in self?.applyConfig() }
        applyConfig()
    }

    func toggle() {
        if panel?.isVisible == true { hide() } else { show() }
    }

    func show() {
        let panel = panel ?? makePanel()
        if NSApp.keyWindow !== panel { previousKeyWindow = NSApp.keyWindow }
        let surface = model.startIfNeeded()
        model.refreshDirectory()
        place(panel)
        panel.makeKeyAndOrderFront(nil)
        if surface.window === panel { panel.makeFirstResponder(surface) }
        directoryTimer?.invalidate()
        directoryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.refreshDirectory() }
        }
    }

    func hide() {
        directoryTimer?.invalidate()
        directoryTimer = nil
        guard let panel, panel.isVisible else { return }
        panel.orderOut(nil)
        if NSApp.isActive { previousKeyWindow?.makeKey() }
        previousKeyWindow = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func applyConfig() {
        let settings = configStore.settings.quickTerminal
        let chord = settings.enabled ? settings.hotkey : nil
        if chord != hotKeyChord {
            hotKey = nil
            hotKeyChord = chord
            if let chord {
                hotKey = GlobalHotKey(chord: chord) { [weak self] in self?.toggle() }
                if hotKey == nil {
                    configStore.report([Diagnostic(message: "Couldn't use \(chord.symbols) for the quick terminal. Another app may already use it.")])
                }
            }
        }
        if !settings.enabled { hide() }
        panel?.appearance = appearance
        model.applyConfig()
    }

    private var appearance: NSAppearance? {
        NSAppearance(named: configStore.theme.appearance == .dark ? .darkAqua : .aqua)
    }

    private func makePanel() -> QuickTerminalPanel {
        let panel = QuickTerminalPanel()
        let hosting = NSHostingView(rootView: QuickTerminalView(model: model))
        hosting.sizingOptions = []
        panel.contentView = hosting
        panel.delegate = self
        panel.appearance = appearance
        self.panel = panel
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let panel = self.panel, event.window === panel else { return event }
            return self.handleKey(event) ? nil : event
        }
        return panel
    }

    private var panelWidth: CGFloat {
        Metrics.quickTerminalWidth + Metrics.quickTerminalShadowMargin * 2
    }

    private func place(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let bottom = visible.minY + visible.height * Metrics.quickTerminalScreenBottomRatio - Metrics.quickTerminalShadowMargin
        let minimum = Metrics.quickTerminalHeaderHeight + model.outputHeight + Metrics.quickTerminalOutputPadding * 2
        let height = max(contentHeight, minimum) + Metrics.quickTerminalShadowMargin * 2
        panel.setFrame(NSRect(x: visible.midX - panelWidth / 2, y: bottom, width: panelWidth, height: height), display: false)
    }

    private func resize(to height: CGFloat) {
        contentHeight = height
        guard let panel else { return }
        let total = height + Metrics.quickTerminalShadowMargin * 2
        let frame = panel.frame
        guard abs(frame.height - total) > 0.5 else { return }
        panel.setFrame(NSRect(x: frame.minX, y: frame.minY, width: frame.width, height: total), display: true)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        guard let surface = model.surface else { return false }
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if flags == .command, let key = KeyChord(event: event)?.key {
            switch key {
            case "enter": model.openInTab()
            case "k": surface.clearScreen()
            case "w": hide()
            case "c": surface.copySelection()
            case "v": surface.pasteClipboard()
            case "a": NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: surface, from: nil)
            case "q", ",": return false
            default: break
            }
            return true
        }
        if flags.isEmpty, event.keyCode == 53, !surface.hasForegroundProcess {
            hide()
            return true
        }
        surface.recordInput()
        return false
    }
}
