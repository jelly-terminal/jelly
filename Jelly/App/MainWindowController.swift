import AppKit
import JellyCore
import JellyTerminal
import SwiftUI

final class MainWindowController: NSWindowController, NSWindowDelegate {
    let model: WindowModel
    var onClose: ((WorkspaceSnapshot) -> Void)?

    private let configStore: ConfigStore
    private let license: LicenseService
    private var keyMonitor: Any?
    private var observerID: UUID?
    private var trafficLights: TrafficLights?

    init(configStore: ConfigStore, projects: ProjectStore, license: LicenseService, snapshot: WorkspaceSnapshot?) {
        self.configStore = configStore
        self.license = license
        model = WindowModel(configStore: configStore, projects: projects, snapshot: snapshot)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 320)
        window.tabbingMode = .disallowed
        window.isMovable = false
        window.titlebarSeparatorStyle = .none
        let hosting = NSHostingController(rootView: RootView(model: model, configStore: configStore, license: license))
        hosting.sizingOptions = []
        hosting.sceneBridgingOptions = []
        window.contentViewController = hosting
        window.setContentSize(NSSize(width: 1100, height: 720))
        if !window.setFrameUsingName(Self.frameName) { window.center() }
        window.setFrameAutosaveName(Self.frameName)
        super.init(window: window)

        window.delegate = self
        model.window = window
        observerID = configStore.observe { [weak self] in self?.applyWindowSettings() }
        applyWindowSettings()
        installKeyMonitor()
        trafficLights = TrafficLights(
            window: window,
            height: Metrics.tabBarHeight,
            leading: Metrics.sidebarInset + Metrics.trafficLightLeading,
            spacing: Metrics.trafficLightSpacing
        )
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        trafficLights?.apply()
    }

    required init?(coder: NSCoder) { fatalError() }

    private static let frameName = "JellyMainWindow"

    func perform(_ action: KeyAction) -> Bool {
        model.actions.perform(action)
    }

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window, self.model.pendingImport == nil,
                  let chord = KeyChord(event: event),
                  let action = self.configStore.config.keybinds[chord],
                  self.perform(action)
            else { return event }
            return nil
        }
    }

    private func applyWindowSettings() {
        guard let window else { return }
        let translucent = configStore.settings.window.backgroundOpacity < 1
        window.isOpaque = !translucent
        window.backgroundColor = translucent ? .clear : NSColor(configStore.theme.background)
        window.appearance = NSAppearance(named: configStore.theme.appearance == .dark ? .darkAqua : .aqua)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard configStore.settings.confirmQuit, model.hasForegroundProcesses else { return true }
        let alert = NSAlert()
        alert.messageText = "Close this window?"
        alert.informativeText = "Processes are still running in some tabs."
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: sender) { response in
            guard response == .alertFirstButtonReturn else { return }
            sender.close()
        }
        return false
    }

    func windowWillClose(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let observerID { configStore.removeObserver(observerID) }
        let snapshot = model.snapshot
        model.terminateAll()
        onClose?(snapshot)
    }
}
