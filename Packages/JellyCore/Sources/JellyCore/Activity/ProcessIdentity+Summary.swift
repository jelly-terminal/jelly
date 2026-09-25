extension ProcessIdentity {
    public var summary: String {
        var words = arguments.isEmpty ? [executable] : arguments
        if words.count > 1, Self.isInterpreter(Self.commandName(words[0])), Self.isLauncher(words[1]) {
            words.removeFirst()
        }
        let parts = words.prefix(Self.summaryWordLimit).enumerated().map { index, word in
            index == 0 ? Self.commandName(word) : Self.shortened(word)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static let summaryWordLimit = 4

    private static func isLauncher(_ word: String) -> Bool {
        guard !word.hasPrefix("-") else { return false }
        let name = String(word.split(separator: "/").last ?? "")
        return !name.isEmpty && !name.contains(".")
    }

    private static func shortened(_ word: String) -> String {
        guard word.contains("/"), !word.hasPrefix("-"), !word.contains("://") else { return word }
        return String(word.split(separator: "/").last ?? Substring(word))
    }
}
