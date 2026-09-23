import AppKit
import JellyCore
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var configStore: ConfigStore!
    private var updater: UpdaterService!
    private var windowControllers: [MainWindowController] = []
    private var pendingOpenURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        configStore = ConfigStore()
        updater = UpdaterService()
        _ = configStore.observe { [weak self] in self?.configChanged() }
        configChanged()
        newWindow()
        pendingOpenURLs.forEach(importFile)
        pendingOpenURLs = []
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
              windowControllers.contains(where: { $0.model.workspace.hasForegroundProcesses })
        else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Quit \(AppInfo.name)?"
        alert.informativeText = "Processes are still running in some tabs."
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard configStore != nil else {
            pendingOpenURLs += urls
            return
        }
        urls.forEach(importFile)
    }

    @objc func newWindow() {
        let controller = MainWindowController(configStore: configStore)
        controller.onClose = { [weak self, weak controller] in
            self?.windowControllers.removeAll { $0 === controller }
        }
        windowControllers.append(controller)
        controller.showWindow(nil)
    }

    @objc func performMenuAction(_ sender: NSMenuItem) {
        guard let action = (sender.representedObject as? KeyActionBox)?.action else { return }
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

    @objc func checkForUpdates() {
        updater.checkForUpdates()
    }

    private var keyController: MainWindowController? {
        windowControllers.first { $0.window?.isKeyWindow == true } ?? windowControllers.last
    }

    private func importFile(_ url: URL) {
        if keyController == nil { newWindow() }
        keyController?.window?.makeKeyAndOrderFront(nil)
        keyController?.model.beginImport(url)
    }

    private func configChanged() {
        NSApp.mainMenu = MainMenu.build(target: self, keybinds: configStore.config.keybinds, updatesAvailable: updater.isAvailable)
        updater.apply(configStore.settings.updates)
    }
}
