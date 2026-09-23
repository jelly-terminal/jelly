import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class SessionModel: Identifiable {
    let id: UUID
    var name: String
    let workspace: WorkspaceModel

    @ObservationIgnored private var pendingTabs: [WorkspaceSnapshot.Tab]
    @ObservationIgnored private var pendingSelection: Int?

    init(id: UUID = UUID(), name: String, configStore: ConfigStore, tabs: [WorkspaceSnapshot.Tab] = [], selectedTab: Int? = nil) {
        self.id = id
        self.name = name
        workspace = WorkspaceModel(configStore: configStore)
        pendingTabs = tabs
        pendingSelection = selectedTab
    }

    var isActivated: Bool {
        pendingTabs.isEmpty && !workspace.tabs.isEmpty
    }

    func activate() {
        guard workspace.tabs.isEmpty else { return }
        let restored = pendingTabs
        pendingTabs = []
        if restored.isEmpty {
            workspace.newTab()
            return
        }
        restored.forEach(workspace.restoreTab)
        if let index = pendingSelection, workspace.tabs.indices.contains(index) {
            workspace.selectedID = workspace.tabs[index].id
        }
    }

    var snapshot: WorkspaceSnapshot.Session {
        guard pendingTabs.isEmpty else {
            return WorkspaceSnapshot.Session(id: id, name: name, tabs: pendingTabs, selectedTab: pendingSelection)
        }
        let tabs = workspace.tabs.map(\.snapshot)
        let selected = workspace.tabs.firstIndex { $0.id == workspace.selectedID }
        return WorkspaceSnapshot.Session(id: id, name: name, tabs: tabs, selectedTab: selected)
    }
}
