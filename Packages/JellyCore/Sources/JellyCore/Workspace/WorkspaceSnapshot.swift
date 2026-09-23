import Foundation

public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    public struct Tab: Codable, Equatable, Sendable {
        public var directory: String?
        public var customTitle: String?

        public init(directory: String?, customTitle: String?) {
            self.directory = directory
            self.customTitle = customTitle
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
