public struct ProcessIdentity: Equatable, Sendable {
    public var executable: String
    public var arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }

    public var commandNames: Set<String> {
        var names: Set<String> = [Self.commandName(executable)]
        if let first = arguments.first {
            let program = Self.commandName(first)
            names.insert(program)
            if Self.isInterpreter(program) || Self.isInterpreter(Self.commandName(executable)), arguments.count > 1 {
                names.insert(Self.commandName(arguments[1]))
            }
        }
        names.remove("")
        return names
    }

    private static let scriptExtensions = [".js", ".mjs", ".cjs", ".ts", ".py", ".rb"]

    static func commandName(_ path: String) -> String {
        var name = String(path.split(separator: "/").last ?? "")
        if name.hasPrefix("-") { name.removeFirst() }
        for suffix in scriptExtensions where name.hasSuffix(suffix) {
            name.removeLast(suffix.count)
            break
        }
        return name
    }

    private static func isInterpreter(_ name: String) -> Bool {
        ["node", "bun", "deno", "ruby"].contains(name) || name.hasPrefix("python")
    }
}
