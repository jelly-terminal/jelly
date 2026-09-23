import Foundation

public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    public struct Pane: Codable, Equatable, Sendable {
        public var id: PaneID
        public var directory: String?

        public init(id: PaneID, directory: String?) {
            self.id = id
            self.directory = directory
        }
    }

    public struct Tab: Codable, Equatable, Sendable {
        public var directory: String?
        public var customTitle: String?
        public var layout: PaneTree?
        public var panes: [Pane]?
        public var focusedPane: PaneID?

        public init(directory: String?, customTitle: String?, layout: PaneTree? = nil, panes: [Pane]? = nil, focusedPane: PaneID? = nil) {
            self.directory = directory
            self.customTitle = customTitle
            self.layout = layout
            self.panes = panes
            self.focusedPane = focusedPane
        }

        public var restorableLayout: PaneTree? {
            guard let layout, let panes else { return nil }
            let ids = layout.panes
            guard Set(ids).count == ids.count, Set(ids) == Set(panes.map(\.id)) else { return nil }
            return layout
        }
    }

    public struct Session: Codable, Equatable, Sendable {
        public var id: UUID
        public var name: String
        public var tabs: [Tab]
        public var selectedTab: Int?

        public init(id: UUID, name: String, tabs: [Tab], selectedTab: Int?) {
            self.id = id
            self.name = name
            self.tabs = tabs
            self.selectedTab = selectedTab
        }
    }

    public struct Project: Codable, Equatable, Sendable {
        public var path: String
        public var name: String

        public init(path: String, name: String) {
            self.path = path
            self.name = name
        }
    }

    public var sessions: [Session]
    public var selectedSession: UUID?
    public var projects: [Project]
    public var sidebarVisible: Bool?

    public init(sessions: [Session], selectedSession: UUID?, projects: [Project], sidebarVisible: Bool?) {
        self.sessions = sessions
        self.selectedSession = selectedSession
        self.projects = projects
        self.sidebarVisible = sidebarVisible
    }
}
