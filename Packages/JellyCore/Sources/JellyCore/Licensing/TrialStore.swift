import Foundation

public struct TrialStore: Sendable {
    public let file: URL

    public init(file: URL) {
        self.file = file
    }

    public static func standard(bundleID: String = Bundle.main.bundleIdentifier ?? "com.monawwar.Jelly") -> TrialStore {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return TrialStore(file: support.appending(path: bundleID).appending(path: "trial.json"))
    }

    public func startedAt() -> Date {
        if let data = try? Data(contentsOf: file), let date = try? JSONDecoder().decode(Date.self, from: data) {
            return date
        }
        let now = Date()
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(now).write(to: file, options: .atomic)
        return now
    }
}
