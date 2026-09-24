public struct AgentSettings: Equatable, Sendable {
    public enum Notify: String, Sendable, CaseIterable {
        case unfocused
        case always
        case never
    }

    public struct Custom: Equatable, Sendable {
        public var name: String
        public var commands: [String]

        public init(name: String, commands: [String]) {
            self.name = name
            self.commands = commands
        }
    }

    public var enabled = true
    public var idleAfter = 5
    public var notify = Notify.unfocused
    public var notifySound = true
    public var notifyFinished = true
    public var watch = ["claude"]
    public var custom: [Custom] = []

    public init() {}
}
