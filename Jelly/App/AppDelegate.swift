import AppKit
import JellyCore
import JellyTerminal
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var configStore: ConfigStore!
    private var updater: UpdaterService!
    private let telemetry = TelemetryService()
    private var whatsNew: WhatsNewPresenter!
    private var onboarding: OnboardingPresenter!
    private var quickTerminal: QuickTerminalController!
    private var windowControllers: [MainWindowController] = []
    private var settingsController: SettingsWindowController?
    private var pendingOpenURLs: [URL] = []
    private let snapshotStore = SnapshotStore.standard()
    private var closedWindows: [WorkspaceSnapshot.Window] = []
    private var frontWindow: Int?
    private var savedSnapshot: WorkspaceSnapshot?
    private var autosave: Timer?
    private var endsSessionsOnQuit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        configStore = ConfigStore()
        updater = UpdaterService()
        whatsNew = WhatsNewPresenter(configStore: configStore)
        onboarding = OnboardingPresenter(configStore: configStore)
        quickTerminal = QuickTerminalController(configStore: configStore) { [weak self] surface in
            self?.adoptQuickTerminal(surface)
        }
        AgentNotifier.shared.onOpen = { [weak self] pane in self?.reveal(pane) }
        AgentNotifier.shared.activate()
        let saved = snapshotStore.load()
        closedWindows = saved?.windows ?? []
        frontWindow = saved?.frontWindow
        MuxClient.shared.prune(keeping: saved?.paneIDs ?? [])
        _ = configStore.observe { [weak self] in self?.configChanged() }
        configChanged()
        if whatsNew.isFirstLaunch {
            onboarding.present { [weak self] in self?.startSession() }
        } else {
            startSession()
        }
        whatsNew.presentIfUpdated()
        autosave = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveSnapshot() }
        }
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { newWindow() }
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard configStore.settings.confirmQuit,
              windowControllers.contains(where: { $0.model.hasForegroundProcesses })
        else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Quit \(AppInfo.name)?"
        guard keepsSessionsOnQuit else {
            alert.informativeText = "Processes are still running in some tabs."
            alert.addButton(withTitle: "Quit")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else {
                endsSessionsOnQuit = false
                return .terminateCancel
            }
            return .terminateNow
        }
        alert.informativeText = "Processes are still running in some tabs. They keep running and come back when you open \(AppInfo.name) again."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Quit and End Sessions")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return .terminateNow
        case .alertSecondButtonReturn:
            endsSessionsOnQuit = true
            return .terminateNow
        default:
            return .terminateCancel
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveSnapshot()
        for controller in windowControllers {
            controller.onClose = nil
            controller.endsProcessesOnClose = false
        }
        if !keepsSessionsOnQuit { MuxClient.shared.endAll() }
    }

    @objc func quitAndEndSessions() {
        endsSessionsOnQuit = true
        NSApp.terminate(nil)
    }

    private var keepsSessionsOnQuit: Bool {
        configStore.settings.session.keepAlive && !endsSessionsOnQuit
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard configStore != nil else {
            pendingOpenURLs += urls
            return
        }
        urls.forEach(importFile)
    }

    @objc func newWindow() {
        guard windowControllers.isEmpty, !closedWindows.isEmpty else {
            openWindow(restoring: nil)
            return
        }
        let restoring = closedWindows
        let front = frontWindow.flatMap { restoring.indices.contains($0) ? $0 : nil } ?? restoring.count - 1
        closedWindows = []
        frontWindow = nil
        let controllers = restoring.map(openWindow)
        controllers[front].window?.makeKeyAndOrderFront(nil)
    }

    @discardableResult
    private func openWindow(restoring snapshot: WorkspaceSnapshot.Window?) -> MainWindowController {
        let controller = MainWindowController(configStore: configStore, updater: updater, snapshot: snapshot)
        controller.onClose = { [weak self, weak controller] snapshot in
            guard let self else { return }
            self.windowControllers.removeAll { $0 === controller }
            if self.windowControllers.isEmpty { self.closedWindows = [snapshot] }
            self.saveSnapshot()
        }
        windowControllers.append(controller)
        controller.showWindow(nil)
        return controller
    }

    @objc func performMenuAction(_ sender: NSMenuItem) {
        guard let action = (sender.representedObject as? KeyActionBox)?.action else { return }
        if action == .settingsOpen {
            showSettings()
            return
        }
        if let settingsWindow = settingsController?.window, settingsWindow.isKeyWindow {
            switch action {
            case .copy:
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: sender)
                return
            case .paste:
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: sender)
                return
            case .paneClose, .tabClose:
                settingsWindow.performClose(sender)
                return
            default:
                break
            }
        }
        if let controller = keyController {
            guard !controller.perform(action) else { return }
            switch action {
            case .copy: NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: sender)
            case .paste: NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: sender)
            default: break
            }
            return
        }
        switch action {
        case .tabNew: newWindow()
        case .configOpen: configStore.openConfigFile()
        case .configReload: configStore.reload()
        default: break
        }
    }

    @objc func importConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "toml") ?? .plainText]
        panel.allowsMultipleSelection = false
        panel.message = "Choose a TOML file with settings, keybinds or themes"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        importFile(url)
    }

    @objc func showSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(
                configStore: configStore,
                updatesAvailable: updater.isAvailable,
                onCheckForUpdates: { [weak self] in self?.checkForUpdates() },
                onImportTheme: { [weak self] in self?.importConfig() }
            )
        }
        settingsController?.showWindow(nil)
        settingsController?.window?.makeKeyAndOrderFront(nil)
    }

    @objc func showWhatsNew() {
        whatsNew.present()
    }

    @objc func showWelcome() {
        onboarding.present()
    }

    @objc func reportBug() {
        NSWorkspace.shared.open(SupportLinks.reportBug)
    }

    @objc func openDocumentation() {
        NSWorkspace.shared.open(SupportLinks.documentation)
    }

    @objc func openRepository() {
        NSWorkspace.shared.open(SupportLinks.repository)
    }

    @objc func checkForUpdates() {
        updater.checkForUpdates()
    }

    private func startSession() {
        newWindow()
        pendingOpenURLs.forEach(importFile)
        pendingOpenURLs = []
    }

    private var keyController: MainWindowController? {
        windowControllers.first { $0.window?.isKeyWindow == true } ?? windowControllers.last
    }

    private func reveal(_ pane: PaneID) {
        guard let controller = windowControllers.first(where: { $0.model.reveal(pane) }) else { return }
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func adoptQuickTerminal(_ surface: TerminalSurface) {
        if keyController == nil { newWindow() }
        guard let controller = keyController else {
            surface.stop()
            return
        }
        controller.model.workspace.adoptTab(surface)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
        controller.model.focusTerminal()
    }

    private func importFile(_ url: URL) {
        if keyController == nil { newWindow() }
        keyController?.window?.makeKeyAndOrderFront(nil)
        keyController?.model.beginImport(url)
    }

    private func saveSnapshot() {
        let snapshot = windowControllers.isEmpty
            ? WorkspaceSnapshot(windows: closedWindows, frontWindow: nil)
            : WorkspaceSnapshot(windows: windowControllers.map(\.model.snapshot), frontWindow: frontIndex)
        guard snapshot != savedSnapshot else { return }
        snapshotStore.save(snapshot)
        savedSnapshot = snapshot
        MuxClient.shared.prune(keeping: snapshot.paneIDs)
    }

    private var frontIndex: Int? {
        NSApp.orderedWindows.lazy.compactMap { window in
            self.windowControllers.firstIndex { $0.window === window }
        }.first
    }

    private func configChanged() {
        NSApp.mainMenu = MainMenu.build(
            target: self,
            keybinds: configStore.config.keybinds,
            updatesAvailable: updater.isAvailable,
            keepsSessions: configStore.settings.session.keepAlive
        )
        updater.apply(configStore.settings.updates)
        telemetry.apply(configStore.settings.telemetry)
    }
}
