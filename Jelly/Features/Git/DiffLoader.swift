import Foundation
import JellyCore

nonisolated enum DiffLoader {
    @concurrent
    static func load(_ target: DiffTarget) async -> ViewerContent {
        guard let data = await GitClient.diff(target) else { return .unavailable("Couldn’t read this change.") }
        guard data.count <= GitRunner.outputLimit else { return .unavailable("This diff is too large to show.") }
        let diff = DiffParser.parse(String(decoding: data, as: UTF8.self))
        if diff.isBinary {
            if target.change.kind != .deleted, case .image(let image) = await ViewerLoader.load(target.url) { return .image(image) }
            return .unavailable("Binary file changed.")
        }
        guard !diff.hunks.isEmpty else {
            return .unavailable(target.change.kind == .renamed ? "Renamed without changes." : "No changes to show.")
        }
        return .diff(DiffDocument(diff, language: ViewerLoader.language(for: target.url)))
    }
}
