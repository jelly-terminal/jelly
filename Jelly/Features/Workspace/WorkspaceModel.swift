import AppKit
import JellyCore
import JellyTerminal
import Observation
import SwiftUI

@Observable
final class WorkspaceModel {
    private(set) var tabs: [TabModel] = []
    var selectedID: UUID?

    @ObservationIgnored let configStore: ConfigStore
    @ObservationIgnored private var observerID: UUID?

    init(configStore: ConfigStore) {
        self.configStore = configStore
        observerID = configStore.observe { [weak self] in self?.applyConfig() }
    }

    isolated deinit {
        if let observerID { configStore.removeObserver(observerID) }
    }

    var selectedTab: TabModel? {
        tabs.first { $0.id == selectedID }
    }

    @discardableResult
    func newTab(directory: String? = nil) -> TabModel {
        let settings = configStore.settings
        var shell = settings.shell
        if let directory { shell.workingDirectory = .path(directory) }
        let surface = TerminalSurface(appVersion: AppInfo.version, settings: settings, theme: configStore.theme)
        if let reference = tabs.first?.surface, reference.frame.size != .zero {
            surface.frame = reference.frame
        }
        configStore.report(surface.apply(settings: settings, theme: configStore.theme))
        let tab = TabModel(surface: surface)
        surface.onExit = { [weak self, weak tab] _ in
            guard let self, let tab else { return }
            self.close(tab)
        }
        let index = selectedTab.flatMap { current in tabs.firstIndex { $0 === current } }.map { $0 + 1 } ?? tabs.count
        tabs.insert(tab, at: index)
        surface.start(shell: shell, inheritedDirectory: selectedTab?.surface.workingDirectory)
        selectedID = tab.id
        return tab
    }

    func close(_ tab: TabModel) {
        guard let index = tabs.firstIndex(where: { $0 === tab }) else { return }
        tab.surface.stop()
        tabs.remove(at: index)
        if selectedID == tab.id {
            selectedID = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)].id
        }
    }

    func requestClose(_ tab: TabModel, in window: NSWindow?) {
        guard tab.surface.hasForegroundProcess, configStore.settings.confirmQuit, let window else {
            close(tab)
            return
        }
        let alert = NSAlert()
        alert.messageText = "Close “\(tab.displayTitle)”?"
        alert.informativeText = "A process is still running in this tab."
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self, weak tab] response in
            guard response == .alertFirstButtonReturn, let tab else { return }
            self?.close(tab)
        }
    }

    func select(offset: Int) {
        guard let current = selectedTab, let index = tabs.firstIndex(where: { $0 === current }), !tabs.isEmpty else { return }
        selectedID = tabs[(index + offset + tabs.count) % tabs.count].id
    }

    func select(number: Int) {
        guard !tabs.isEmpty else { return }
        selectedID = number >= 9 ? tabs.last?.id : tabs[min(number - 1, tabs.count - 1)].id
    }

    func move(_ tab: TabModel, to index: Int) {
        guard let from = tabs.firstIndex(where: { $0 === tab }) else { return }
        tabs.move(fromOffsets: IndexSet(integer: from), toOffset: index)
    }

    var hasForegroundProcesses: Bool {
        tabs.contains { $0.surface.hasForegroundProcess }
    }

    func terminateAll() {
        tabs.forEach { $0.surface.stop() }
    }

    private func applyConfig() {
        let settings = configStore.settings
        let theme = configStore.theme
        for tab in tabs {
            configStore.report(tab.surface.apply(settings: settings, theme: theme))
        }
    }
}
