import JellyCore
import Testing
@testable import JellyTerminal

struct ShellLaunchTests {
    private func context(
        login: String? = "/bin/zsh",
        env: [String: String] = ["SHELL": "/bin/bash", "PATH": "/usr/bin"],
        installed: Set<String> = ["/bin/zsh", "/bin/bash", "/opt/homebrew/bin/fish"],
        inherited: String? = nil
    ) -> ShellLaunch.Context {
        ShellLaunch.Context(
            loginShell: login,
            environment: env,
            home: "/Users/me",
            inheritedDirectory: inherited,
            appVersion: "0.1.0",
            paneID: "pane",
            isExecutable: { installed.contains($0) }
        )
    }

    @Test func configuredProgramWinsThenLoginShellThenSHELL() {
        var settings = ShellSettings()
        settings.program = "/opt/homebrew/bin/fish"
        #expect(ShellLaunch.resolve(settings, context: context()).executable == "/opt/homebrew/bin/fish")

        settings.program = "/missing/fish"
        #expect(ShellLaunch.resolve(settings, context: context()).executable == "/bin/zsh")
        #expect(ShellLaunch.resolve(settings, context: context(login: nil)).executable == "/bin/bash")
        #expect(ShellLaunch.resolve(settings, context: context(login: nil, env: [:])).executable == ShellLaunch.fallbackShell)
    }

    @Test func startsAsLoginShellInTheRightDirectory() {
        var settings = ShellSettings()
        settings.program = "/opt/homebrew/bin/fish"
        let launch = ShellLaunch.resolve(settings, context: context(inherited: "/Users/me/Projects"))
        #expect(launch.argv0 == "-fish")
        #expect(launch.directory == "/Users/me/Projects")

        settings.workingDirectory = .path("~/code")
        #expect(ShellLaunch.resolve(settings, context: context(inherited: "/tmp")).directory == "/Users/me/code")
    }

    @Test func environmentIdentifiesJellyAndDropsOtherTerminals() {
        var settings = ShellSettings()
        settings.env = ["EDITOR": "nvim", "TERM": "xterm-kitty"]
        let launch = ShellLaunch.resolve(settings, context: context(env: [
            "PATH": "/usr/bin", "TERM_SESSION_ID": "x", "GHOSTTY_RESOURCES_DIR": "/g", "LC_CTYPE": "UTF-8",
        ]))
        let env = Dictionary(uniqueKeysWithValues: launch.environment.map { line in
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            return (parts[0], parts[1])
        })
        #expect(env["TERM_PROGRAM"] == "Jelly")
        #expect(env["COLORTERM"] == "truecolor")
        #expect(env["TERM"] == "xterm-kitty")
        #expect(env["EDITOR"] == "nvim")
        #expect(env["PATH"] == "/usr/bin")
        #expect(env["LANG"] == nil)
        #expect(env["TERM_SESSION_ID"] == nil && env["GHOSTTY_RESOURCES_DIR"] == nil)
    }
}
