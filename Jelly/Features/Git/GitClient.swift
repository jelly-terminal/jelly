import Foundation
import JellyCore

nonisolated enum GitClient {
    @concurrent
    static func lookup(_ directory: URL) async -> GitLookup {
        guard GitRunner.executable != nil else { return .gitMissing }
        guard let data = await GitRunner.run(["rev-parse", "--show-toplevel"], in: directory) else { return .notRepository }
        let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .newlines)
        guard !path.isEmpty else { return .notRepository }
        return .repository(URL(filePath: path, directoryHint: .isDirectory).standardizedFileURL)
    }

    @concurrent
    static func status(of repository: URL) async -> GitStatus? {
        let arguments = ["status", "--porcelain=v2", "-z", "--branch", "--untracked-files=all"]
        guard let data = await GitRunner.run(arguments, in: repository) else { return nil }
        return GitStatusParser.parse(String(decoding: data, as: UTF8.self))
    }

    @concurrent
    static func diff(_ target: DiffTarget) async -> Data? {
        let change = target.change
        let base = ["-c", "core.quotePath=false", "diff", "--no-color", "--no-ext-diff"]
        switch change.area {
        case .staged:
            return await GitRunner.run(base + ["--cached", "-M", "--"] + [change.originalPath, change.path].compactMap { $0 }, in: target.repository)
        case .unstaged, .conflicted:
            return await GitRunner.run(base + ["--", change.path], in: target.repository)
        case .untracked:
            return await GitRunner.run(base + ["--no-index", "--", "/dev/null", change.path], in: target.repository, accepting: [0, 1])
        }
    }
}
