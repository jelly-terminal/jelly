import AppKit
import JellyCore
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var configStore: ConfigStore!
    private var updater: UpdaterService!
    private var license: LicenseService!
    private var projects: ProjectStore!
    private var windowControllers: [MainWindowController] = []
    private var activationController: ActivationWindowController?
    private var settingsController: SettingsWindowController?
    private var pendingOpenURLs: [URL] = []
    private let snapshotStore = SnapshotStore.standard()
    private var lastSnapshot: WorkspaceSnapshot?
    private var savedSnapshot: WorkspaceSnapshot?
    private var autosave: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configStore = ConfigStore()
        updater = UpdaterService()
        license = LicenseService()
        license.onChange = { [weak self] in self?.configChanged() }
        lastSnapshot = snapshotStore.load()
        projects = ProjectStore(lastSnapshot?.projects ?? [])
        _ = configStore.observe { [weak self] in self?.configChanged() }
        configChanged()
        switch license.status {
        case .licensed:
            startSession()
        case .trial:
            startSession()
            keyController?.model.isLicenseSheetPresented = true
        case .trialExpired:
            presentActivation()
        }
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
        alert.informativeText = "Processes are still running in some tabs."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveSnapshot()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard configStore != nil, activationController == nil else {
            pendingOpenURLs += urls
            return
        }
        urls.forEach(importFile)
    }

    @objc func newWindow() {
        guard license.status.allowsUsage, activationController == nil else {
            presentActivation()
            return
        }
        let restore = windowControllers.isEmpty ? lastSnapshot : nil
        let controller = MainWindowController(configStore: configStore, projects: projects, license: license, snapshot: restore)
        controller.onClose = { [weak self, weak controller] snapshot in
            guard let self else { return }
            if self.windowControllers.first === controller { self.lastSnapshot = snapshot }
            self.windowControllers.removeAll { $0 === controller }
            self.saveSnapshot()
        }
        windowControllers.append(controller)
        controller.showWindow(nil)
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
            _ = controller.perform(action)
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

    @objc func checkForUpdates() {
        updater.checkForUpdates()
    }

    @objc func showLicenseSheet() {
        if let controller = keyController {
            controller.window?.makeKeyAndOrderFront(nil)
            controller.model.isLicenseSheetPresented = true
        } else {
            presentActivation()
        }
    }

    private func startSession() {
        newWindow()
        pendingOpenURLs.forEach(importFile)
        pendingOpenURLs = []
    }

    private func presentActivation() {
        if activationController == nil {
            activationController = ActivationWindowController(
                license: license,
                onActivated: { [weak self] in
                    self?.activationController = nil
                    self?.startSession()
                },
                onDismiss: { [weak self] in
                    guard let self, self.license.status.allowsUsage else {
                        NSApp.terminate(nil)
                        return
                    }
                    self.activationController?.close()
                    self.activationController = nil
                    self.startSession()
                }
            )
        }
        activationController?.showWindow(nil)
        activationController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private var keyController: MainWindowController? {
        windowControllers.first { $0.window?.isKeyWindow == true } ?? windowControllers.last
    }

    private func importFile(_ url: URL) {
        if keyController == nil { newWindow() }
        keyController?.window?.makeKeyAndOrderFront(nil)
        keyController?.model.beginImport(url)
    }

    private func saveSnapshot() {
        var snapshot = windowControllers.first?.model.snapshot ?? lastSnapshot
        snapshot?.projects = projects.snapshot
        guard let snapshot, snapshot != savedSnapshot else { return }
        snapshotStore.save(snapshot)
        savedSnapshot = snapshot
    }

    private func configChanged() {
        NSApp.mainMenu = MainMenu.build(
            target: self,
            keybinds: configStore.config.keybinds,
            updatesAvailable: updater.isAvailable,
            licenseStatus: license.status
        )
        updater.apply(configStore.settings.updates)
    }
}
