import Foundation
import Testing
@testable import JellyCore

struct AgentTests {
    private let start = ContinuousClock.now

    private func guess(output: Int? = nil, input: Int? = nil, alert: Int? = nil, now: Int) -> AgentState {
        var activity = TerminalActivity()
        activity.lastOutput = output.map { start + .seconds($0) }
        activity.lastInput = input.map { start + .seconds($0) }
        activity.lastAlert = alert.map { start + .seconds($0) }
        activity.alertMessage = alert == nil ? nil : "ping"
        return AgentState.guessed(from: activity, since: start, now: start + .seconds(now), quietAfter: .seconds(5))
    }

    @Test func claudeSessionStatusMapsToState() {
        func state(_ json: String, pid: Int32 = 42) -> AgentState? {
            ClaudeCodeAgent.state(fromSession: Data(json.utf8), pid: pid)
        }
        #expect(state(#"{"pid":42,"status":"busy"}"#) == .working)
        #expect(state(#"{"pid":42,"status":"idle"}"#) == .idle)
        #expect(state(#"{"pid":42,"status":"waiting","waitingFor":"permission prompt"}"#) == .needsInput("permission prompt"))
        #expect(state(#"{"pid":7,"status":"busy"}"#) == nil)
        #expect(state(#"{"pid":42}"#) == nil)
        #expect(state("not json") == nil)
    }

    @Test func guessedStateUsesQuietTimeAndAlerts() {
        #expect(guess(now: 2) == .working)
        #expect(guess(now: 5) == .idle)
        #expect(guess(output: 2, input: 9, now: 12) == .working)
        #expect(guess(output: 9, alert: 8, now: 10) == .needsInput("ping"))
        #expect(guess(output: 9, input: 8, alert: 7, now: 10) == .working)
        #expect(guess(output: 9, alert: -1, now: 10) == .working)
    }

    @Test func matchesNativeBinariesAndScriptsRunByAnInterpreter() {
        var settings = AgentSettings()
        settings.watch = AgentCatalog.builtIn.map(\.id)
        let catalog = AgentCatalog(settings: settings)
        let native = ProcessIdentity(executable: "/Users/me/.local/share/claude/versions/2.1.0", arguments: ["claude", "--resume"])
        let node = ProcessIdentity(executable: "/opt/homebrew/bin/node", arguments: ["node", "/opt/homebrew/bin/codex"])
        let python = ProcessIdentity(executable: "/usr/bin/python3.12", arguments: ["/usr/bin/python3.12", "/Users/me/.local/bin/aider"])
        let script = ProcessIdentity(executable: "/usr/local/bin/node", arguments: ["node", "/usr/lib/gemini/index.js"])
        #expect(catalog.match(native)?.id == "claude")
        #expect(catalog.match(node)?.id == "codex")
        #expect(catalog.match(python)?.id == "aider")
        #expect(catalog.match(script) == nil)
        #expect(catalog.match(ProcessIdentity(executable: "/usr/bin/vim", arguments: ["vim", "claude"])) == nil)
    }

    @Test func onlyClaudeIsWatchedByDefault() {
        let catalog = AgentCatalog(settings: AgentSettings())
        #expect(catalog.providers.map(\.id) == ["claude"])
    }

    @Test func watchListAndCustomAgentsComeFromConfig() {
        let document = ConfigDocument(parsing: """
        [settings.agents]
        watch = ["codex", "nope"]
        custom = [{ name = "Codex Fork", commands = ["codex"] }, { name = "Broken" }]
        notify = "sometimes"
        """)
        let agents = document.settings.agents
        #expect(agents.watch == ["codex", "nope"])
        #expect(agents.custom == [AgentSettings.Custom(name: "Codex Fork", commands: ["codex"])])
        #expect(agents.notify == .unfocused)
        #expect(document.diagnostics.map(\.line) == [2, 3, 4])

        let catalog = AgentCatalog(settings: agents)
        #expect(catalog.match(ProcessIdentity(executable: "/bin/codex", arguments: ["codex"]))?.name == "Codex Fork")
        #expect(catalog.match(ProcessIdentity(executable: "/bin/claude", arguments: ["claude"])) == nil)
    }
}
