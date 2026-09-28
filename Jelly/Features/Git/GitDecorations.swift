import Foundation
import JellyCore

struct GitDecorations: Equatable {
    private var files: [String: GitChange.Kind] = [:]
    private var folders: [String: GitChange.Kind] = [:]

    init() {}

    init(status: GitStatus, repository: URL) {
        let root = Self.key(repository)
        for change in status.changes {
            let path = root + "/" + change.path
            files[path] = Self.prominent(files[path], change.kind)
            var folder = (path as NSString).deletingLastPathComponent
            while folder.count > root.count {
                folders[folder] = Self.prominent(folders[folder], change.kind)
                folder = (folder as NSString).deletingLastPathComponent
            }
        }
    }

    func kind(for entry: ExplorerEntry) -> GitChange.Kind? {
        let key = Self.key(entry.url)
        return entry.isDirectory ? folders[key] : files[key]
    }

    private static func key(_ url: URL) -> String {
        let path = url.standardizedFileURL.path(percentEncoded: false)
        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }

    private static func prominent(_ current: GitChange.Kind?, _ candidate: GitChange.Kind) -> GitChange.Kind {
        guard let current, current.prominence >= candidate.prominence else { return candidate }
        return current
    }
}
