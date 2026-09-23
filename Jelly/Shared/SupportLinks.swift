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
            URLQueryItem(name: "title", value: ""),
            URLQueryItem(name: "body", value: bugReportBody),
        ]
        return components.url!
    }

    private static var bugReportBody: String {
        """
        **What happened**


        **What you expected**


        **Steps to reproduce**


        **Environment**
        - Jelly \(AppInfo.version)
        - macOS \(ProcessInfo.processInfo.operatingSystemVersionString)
        """
    }
}
