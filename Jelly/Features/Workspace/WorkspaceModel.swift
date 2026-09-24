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
        let pane = makePane(directory: directory, inheritedDirectory: selectedTab?.surface.workingDirectory)
        let tab = TabModel(pane: pane)
        insert(tab)
        return tab
    }

    func restoreTab(_ snapshot: WorkspaceSnapshot.Tab) {
        let tab: TabModel
        if let layout = snapshot.restorableLayout, let saved = snapshot.panes {
            let panes = saved.map { makePane(id: $0.id, directory: $0.directory, inheritedDirectory: nil) }
            tab = TabModel(panes: panes, layout: layout, focused: snapshot.focusedPane)
        } else {
            tab = TabModel(pane: makePane(directory: snapshot.directory, inheritedDirectory: nil))
        }
        tab.customTitle = snapshot.customTitle
        insert(tab)
    }

    func split(_ axis: PaneTree.Axis, pane target: PaneID? = nil) {
        guard let tab = selectedTab else { return }
        let target = target ?? tab.focusedPaneID
        let pane = makePane(directory: nil, inheritedDirectory: tab.panes[target]?.surface.workingDirectory)
        watchExit(of: pane, in: tab)
        tab.insert(pane, splitting: target, axis: axis)
    }

    func close(_ tab: TabModel) {
        guard let index = tabs.firstIndex(where: { $0 === tab }) else { return }
        tab.stop()
        tabs.remove(at: index)
        if selectedID == tab.id {
            selectedID = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)].id
        }
    }

    func close(_ pane: PaneModel, in tab: TabModel) {
        guard tab.panes.count > 1 else {
            close(tab)
            return
        }
        pane.surface.stop()
        tab.remove(pane.id)
    }

    func requestClose(_ tab: TabModel, in window: NSWindow?) {
        confirm(
            tab.hasForegroundProcess,
            title: "Close “\(tab.displayTitle)”?",
            detail: "A process is still running in this tab.",
            in: window
        ) { [weak self, weak tab] in
            guard let tab else { return }
            self?.close(tab)
        }
    }

    func requestClose(_ pane: PaneModel, in tab: TabModel, window: NSWindow?) {
        confirm(
            pane.surface.hasForegroundProcess,
            title: "Close “\(pane.displayTitle)”?",
            detail: "A process is still running in this pane.",
            in: window
        ) { [weak self, weak pane, weak tab] in
            guard let pane, let tab else { return }
            self?.close(pane, in: tab)
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

    func moveSelected(by offset: Int) {
        guard let current = selectedTab, let index = tabs.firstIndex(where: { $0 === current }) else { return }
        let target = min(max(index + offset, 0), tabs.count - 1)
        guard target != index else { return }
        tabs.move(fromOffsets: IndexSet(integer: index), toOffset: target > index ? target + 1 : target)
    }

    func move(_ tab: TabModel, before target: TabModel) {
        guard tab !== target,
              let from = tabs.firstIndex(where: { $0 === tab }),
              let to = tabs.firstIndex(where: { $0 === target })
        else { return }
        tabs.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
    }

    var agentTone: AgentTone? {
        AgentTone.summary(of: tabs.lazy.compactMap(\.agentTone))
    }

    var hasForegroundProcesses: Bool {
        tabs.contains { $0.hasForegroundProcess }
    }

    func terminateAll() {
        tabs.forEach { $0.stop() }
    }

    private func insert(_ tab: TabModel) {
        tab.orderedPanes.forEach { watchExit(of: $0, in: tab) }
        let index = selectedTab.flatMap { current in tabs.firstIndex { $0 === current } }.map { $0 + 1 } ?? tabs.count
        tabs.insert(tab, at: index)
        selectedID = tab.id
    }

    private func makePane(id: PaneID = PaneID(), directory: String?, inheritedDirectory: String?) -> PaneModel {
        let settings = configStore.settings
        var shell = settings.shell
        if let directory { shell.workingDirectory = .path(directory) }
        let surface = TerminalSurface(paneID: id, appVersion: AppInfo.version, settings: settings, theme: configStore.theme)
        if let reference = selectedTab?.surface, reference.frame.size != .zero {
            surface.frame = reference.frame
        }
        configStore.report(surface.apply(settings: settings, theme: configStore.theme))
        surface.start(shell: shell, inheritedDirectory: inheritedDirectory)
        return PaneModel(surface: surface)
    }

    private func watchExit(of pane: PaneModel, in tab: TabModel) {
        pane.surface.onExit = { [weak self, weak pane, weak tab] _ in
            guard let self, let pane, let tab else { return }
            self.close(pane, in: tab)
        }
    }

    private func confirm(_ needed: Bool, title: String, detail: String, in window: NSWindow?, action: @escaping () -> Void) {
        guard needed, configStore.settings.confirmQuit, let window else {
            action()
            return
        }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            action()
        }
    }

    private func applyConfig() {
        let settings = configStore.settings
        let theme = configStore.theme
        for tab in tabs {
            for pane in tab.panes.values {
                configStore.report(pane.surface.apply(settings: settings, theme: theme))
            }
        }
    }
}
