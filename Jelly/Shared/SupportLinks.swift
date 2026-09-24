import Foundation

enum SupportLinks {
    static var repository: URL {
        URL(string: "https://github.com/\(ReleaseNotesLoader.repository)")!
    }

    static var documentation: URL {
        repository.appendingPathComponent("tree/main/docs")
    }

    static var reportBug: URL {
        var components = URLComponents(url: repository.appendingPathComponent("issues/new"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "template", value: "bug_report.yml"),
        ]
        return components.url!
    }

}
