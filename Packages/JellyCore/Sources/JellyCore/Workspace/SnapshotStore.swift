import Foundation

public struct SnapshotStore: Sendable {
    public let file: URL

    public init(file: URL) {
        self.file = file
    }

    public static func standard(bundleID: String = Bundle.main.bundleIdentifier ?? "com.monawwar.Jelly") -> SnapshotStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SnapshotStore(file: support.appending(path: bundleID).appending(path: "workspace.json"))
    }

    public func load() -> WorkspaceSnapshot? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(WorkspaceSnapshot.self, from: data)
    }

    public func save(_ snapshot: WorkspaceSnapshot) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
    }
}
