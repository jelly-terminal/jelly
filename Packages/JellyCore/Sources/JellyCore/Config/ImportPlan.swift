public struct ImportPlan: Sendable {
    public struct Change: Equatable, Sendable {
        public var path: [String]
        public var old: TOMLValue?
        public var new: TOMLValue

        public var key: String { TOMLWriter.keyPath(Array(path.dropFirst())) }
    }

    public struct ThemeImport: Sendable {
        public var theme: Theme
        public var table: TOMLTable
        public var replaces: Bool
    }

    public var settingChanges: [Change] = []
    public var keybindChanges: [Change] = []
    public var themes: [ThemeImport] = []
    public var diagnostics: [Diagnostic] = []
    public var canApply = true

    public var isEmpty: Bool {
        settingChanges.isEmpty && keybindChanges.isEmpty && themes.isEmpty
    }

    public var summary: String {
        let added = themes.filter { !$0.replaces }.count
        let replaced = themes.count - added
        let parts = [
            added > 0 ? count(added, "theme", verb: "adds") : nil,
            replaced > 0 ? count(replaced, "theme", verb: "updates") : nil,
            settingChanges.isEmpty ? nil : count(settingChanges.count, "setting", verb: "changes"),
            keybindChanges.isEmpty ? nil : count(keybindChanges.count, "keybind", verb: "changes"),
        ].compactMap { $0 }
        return parts.isEmpty ? "No changes" : parts.joined(separator: ", ").capitalizedFirst
    }

    private func count(_ n: Int, _ noun: String, verb: String) -> String {
        "\(verb) \(n) \(noun)\(n == 1 ? "" : "s")"
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
