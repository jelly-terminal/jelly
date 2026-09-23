import Foundation

nonisolated struct ExplorerEntry: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let isDirectory: Bool

    var id: URL { url }

    var isMarkdown: Bool {
        ["md", "markdown", "mdown", "mkd"].contains(url.pathExtension.lowercased())
    }
}
