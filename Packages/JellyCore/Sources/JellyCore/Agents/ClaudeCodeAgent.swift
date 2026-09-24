import Foundation

public struct ClaudeCodeAgent: AgentProvider {
    public let id = "claude"
    public let name = "Claude Code"
    public let sessionsDirectory: URL

    public init(sessionsDirectory: URL = Self.defaultSessionsDirectory) {
        self.sessionsDirectory = sessionsDirectory
    }

    public static var defaultSessionsDirectory: URL {
        let environment = ProcessInfo.processInfo.environment
        let configDirectory = environment["CLAUDE_CONFIG_DIR"].map { URL(filePath: ($0 as NSString).expandingTildeInPath) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: ".claude")
        return configDirectory.appending(path: "sessions")
    }

    public func matches(_ process: ProcessIdentity) -> Bool {
        process.commandNames.contains("claude")
    }

    public func state(ofProcess pid: Int32) -> AgentState? {
        guard let data = try? Data(contentsOf: sessionsDirectory.appending(path: "\(pid).json")) else { return nil }
        return Self.state(fromSession: data, pid: pid)
    }

    static func state(fromSession data: Data, pid: Int32) -> AgentState? {
        guard let session = try? JSONDecoder().decode(Session.self, from: data), session.pid == pid else { return nil }
        switch session.status {
        case "busy": return .working
        case "idle": return .idle
        case "waiting": return .needsInput(session.waitingFor)
        default: return nil
        }
    }

    private struct Session: Decodable {
        let pid: Int32
        let status: String?
        let waitingFor: String?
    }
}
