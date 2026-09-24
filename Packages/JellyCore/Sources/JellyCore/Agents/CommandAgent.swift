public struct CommandAgent: AgentProvider, Equatable {
    public let id: String
    public let name: String
    public let commands: Set<String>

    public init(id: String, name: String, commands: Set<String>) {
        self.id = id
        self.name = name
        self.commands = commands
    }

    public func matches(_ process: ProcessIdentity) -> Bool {
        !commands.isDisjoint(with: process.commandNames)
    }
}
