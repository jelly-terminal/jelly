import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class SessionModel: Identifiable {
    let id: UUID
    var name: String
    var color: SessionColor
    let workspace: WorkspaceModel

    @ObservationIgnored private var pendingTabs: [WorkspaceSnapshot.Tab]
    @ObservationIgnored private var pendingSelection: Int?

    init(id: UUID = UUID(), name: String, color: SessionColor = .default, configStore: ConfigStore, tabs: [WorkspaceSnapshot.Tab] = [], selectedTab: Int? = nil) {
        self.id = id
        self.name = name
        self.color = color
        workspace = WorkspaceModel(configStore: configStore)
        pendingTabs = tabs
        pendingSelection = selectedTab
    }

    var isActivated: Bool {
        pendingTabs.isEmpty && !workspace.tabs.isEmpty
    }

    var tabCount: Int {
        pendingTabs.isEmpty ? workspace.tabs.count : pendingTabs.count
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
            return WorkspaceSnapshot.Session(id: id, name: name, color: color, tabs: pendingTabs, selectedTab: pendingSelection)
        }
        let tabs = workspace.tabs.map(\.snapshot)
        let selected = workspace.tabs.firstIndex { $0.id == workspace.selectedID }
        return WorkspaceSnapshot.Session(id: id, name: name, color: color, tabs: tabs, selectedTab: selected)
    }
}
