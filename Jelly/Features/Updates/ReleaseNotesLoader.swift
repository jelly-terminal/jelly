import Foundation
import JellyCore

enum ReleaseNotesLoader {
    nonisolated static let repository = "jelly-terminal/jelly"

    @concurrent
    nonisolated static func load(version: String) async -> MarkdownDocument? {
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases/tags/v\(version)") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let release = try? JSONDecoder().decode(Release.self, from: data),
              let body = release.body, !body.isEmpty
        else { return nil }
        return MarkdownDocument(body)
    }

    private nonisolated struct Release: Decodable, Sendable {
        let body: String?
    }
}
