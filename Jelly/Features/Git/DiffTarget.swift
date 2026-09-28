import Foundation
import JellyCore

nonisolated struct DiffTarget: Hashable, Sendable {
    let change: GitChange
    let repository: URL

    var url: URL {
        repository.appending(path: change.path).standardizedFileURL
    }
}
