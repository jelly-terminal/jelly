import Foundation
import JellyCore

public struct ShellLaunch: Equatable, Sendable {
    public var executable: String
    public var argv0: String
    public var args: [String]
    public var environment: [String]
    public var directory: String

    public struct Context: Sendable {
        public var loginShell: String?
        public var environment: [String: String]
        public var home: String
        public var inheritedDirectory: String?
        public var appVersion: String
        public var paneID: String
        public var isExecutable: @Sendable (String) -> Bool

        public init(
            loginShell: String? = ShellLaunch.accountLoginShell(),
            environment: [String: String] = ProcessInfo.processInfo.environment,
            home: String = NSHomeDirectory(),
            inheritedDirectory: String? = nil,
            appVersion: String,
            paneID: String,
            isExecutable: @escaping @Sendable (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
        ) {
            self.loginShell = loginShell
            self.environment = environment
            self.home = home
            self.inheritedDirectory = inheritedDirectory
            self.appVersion = appVersion
            self.paneID = paneID
            self.isExecutable = isExecutable
        }
    }

    public static let fallbackShell = "/bin/zsh"

    public static func resolve(_ settings: ShellSettings, context: Context) -> ShellLaunch {
        let candidates = [
            settings.program.map { expandTilde($0, home: context.home) },
            context.loginShell,
            context.environment["SHELL"],
        ]
        let executable = candidates.compactMap { $0 }.first { !$0.isEmpty && context.isExecutable($0) } ?? fallbackShell
        let name = (executable as NSString).lastPathComponent

        let directory: String
        switch settings.workingDirectory {
        case .inherit: directory = context.inheritedDirectory ?? context.home
        case .home: directory = context.home
        case .path(let path): directory = expandTilde(path, home: context.home)
        }

        return ShellLaunch(
            executable: executable,
            argv0: "-" + name,
            args: settings.args,
            environment: environment(settings: settings, context: context),
            directory: directory
        )
    }

    static let droppedVariables = [
        "TERM_SESSION_ID", "ITERM_SESSION_ID", "GHOSTTY_RESOURCES_DIR", "GHOSTTY_BIN_DIR", "__CFBundleIdentifier", "XPC_SERVICE_NAME",
        "CLAUDECODE", "CLAUDE_PID", "CLAUDE_EFFORT", "AI_AGENT", "CLAUDE_CODE_ENTRYPOINT", "CLAUDE_CODE_EXECPATH",
        "CLAUDE_CODE_CHILD_SESSION", "CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_SESSION_ATTENDED",
        "CLAUDE_CODE_MESSAGING_SOCKET", "CLAUDE_CODE_MESSAGING_TOKEN",
    ]

    static func environment(settings: ShellSettings, context: Context) -> [String] {
        var env = context.environment
        for key in droppedVariables {
            env[key] = nil
        }
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["TERM_PROGRAM"] = "Jelly"
        env["TERM_PROGRAM_VERSION"] = context.appVersion
        env["JELLY_PANE"] = context.paneID
        env["HOME"] = env["HOME"] ?? context.home
        if env["LANG"] == nil, env["LC_ALL"] == nil, env["LC_CTYPE"] == nil {
            env["LANG"] = "en_US.UTF-8"
        }
        for (key, value) in settings.env { env[key] = value }
        return env.map { "\($0.key)=\($0.value)" }.sorted()
    }

    static func expandTilde(_ path: String, home: String) -> String {
        if path == "~" { return home }
        if path.hasPrefix("~/") { return home + path.dropFirst() }
        return path
    }

    public static func accountLoginShell() -> String? {
        guard let entry = getpwuid(getuid()), let shell = entry.pointee.pw_shell else { return nil }
        let path = String(cString: shell)
        return path.isEmpty ? nil : path
    }
}
