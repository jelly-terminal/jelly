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
        public var color: SessionColor?
        public var tabs: [Tab]
        public var selectedTab: Int?

        public init(id: UUID, name: String, color: SessionColor? = nil, tabs: [Tab], selectedTab: Int?) {
            self.id = id
            self.name = name
            self.color = color
            self.tabs = tabs
            self.selectedTab = selectedTab
        }
    }

    public struct Window: Codable, Equatable, Sendable {
        public var sessions: [Session]
        public var selectedSession: UUID?
        public var sidebarVisible: Bool?
        public var frame: String?

        public init(sessions: [Session], selectedSession: UUID?, sidebarVisible: Bool?, frame: String? = nil) {
            self.sessions = sessions
            self.selectedSession = selectedSession
            self.sidebarVisible = sidebarVisible
            self.frame = frame
        }
    }

    public var windows: [Window]
    public var frontWindow: Int?

    public init(windows: [Window], frontWindow: Int?) {
        self.windows = windows
        self.frontWindow = frontWindow
    }

    public var paneIDs: Set<PaneID> {
        Set(windows.flatMap(\.sessions).flatMap(\.tabs).flatMap { $0.panes ?? [] }.map(\.id))
    }

    private enum CodingKeys: String, CodingKey {
        case windows, frontWindow, sessions, selectedSession, sidebarVisible
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        frontWindow = try container.decodeIfPresent(Int.self, forKey: .frontWindow)
        if let windows = try container.decodeIfPresent([Window].self, forKey: .windows) {
            self.windows = windows
        } else if let sessions = try container.decodeIfPresent([Session].self, forKey: .sessions) {
            windows = [Window(
                sessions: sessions,
                selectedSession: try container.decodeIfPresent(UUID.self, forKey: .selectedSession),
                sidebarVisible: try container.decodeIfPresent(Bool.self, forKey: .sidebarVisible)
            )]
        } else {
            windows = []
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(windows, forKey: .windows)
        try container.encodeIfPresent(frontWindow, forKey: .frontWindow)
    }
}
