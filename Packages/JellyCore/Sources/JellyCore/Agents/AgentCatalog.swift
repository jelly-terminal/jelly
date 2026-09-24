public struct AgentCatalog: Sendable {
    public static let builtIn: [any AgentProvider] = [
        ClaudeCodeAgent(),
        CommandAgent(id: "codex", name: "Codex", commands: ["codex"]),
        CommandAgent(id: "gemini", name: "Gemini CLI", commands: ["gemini"]),
        CommandAgent(id: "opencode", name: "OpenCode", commands: ["opencode"]),
        CommandAgent(id: "amp", name: "Amp", commands: ["amp"]),
        CommandAgent(id: "cursor", name: "Cursor Agent", commands: ["cursor-agent"]),
        CommandAgent(id: "copilot", name: "Copilot CLI", commands: ["copilot"]),
        CommandAgent(id: "aider", name: "Aider", commands: ["aider"]),
        CommandAgent(id: "goose", name: "Goose", commands: ["goose"]),
        CommandAgent(id: "crush", name: "Crush", commands: ["crush"]),
        CommandAgent(id: "qwen", name: "Qwen Code", commands: ["qwen"]),
    ]

    public let providers: [any AgentProvider]

    public init(providers: [any AgentProvider]) {
        self.providers = providers
    }

    public init(settings: AgentSettings) {
        let custom = settings.custom.map { agent in
            CommandAgent(id: "custom:" + agent.name, name: agent.name, commands: Set(agent.commands))
        }
        let builtIn = Self.builtIn.filter { settings.watch.contains($0.id) }
        self.init(providers: custom + builtIn)
    }

    public func match(_ process: ProcessIdentity) -> (any AgentProvider)? {
        providers.first { $0.matches(process) }
    }
}
