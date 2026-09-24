import Foundation

public struct ConfigPaths: Sendable {
    public var directory: URL
    public var configFileName: String

    public init(directory: URL, configFileName: String = "jelly.toml") {
        self.directory = directory
        self.configFileName = configFileName
    }

    public static func standard(
        configFileName: String = "jelly.toml",
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> ConfigPaths {
        let base: URL
        if let xdg = environment["XDG_CONFIG_HOME"], xdg.hasPrefix("/") {
            base = URL(filePath: xdg, directoryHint: .isDirectory)
        } else {
            base = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".config", directoryHint: .isDirectory)
        }
        return ConfigPaths(directory: base.appending(path: "jelly", directoryHint: .isDirectory), configFileName: configFileName)
    }

    public var configFile: URL { directory.appending(path: configFileName) }
    public var themesDirectory: URL { directory.appending(path: "themes", directoryHint: .isDirectory) }

    public func themeFile(id: String) -> URL {
        themesDirectory.appending(path: "\(id).toml")
    }
}
