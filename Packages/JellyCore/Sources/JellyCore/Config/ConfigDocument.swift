public struct ConfigDocument: Sendable {
    public var table = TOMLTable()
    public var settings = Settings()
    public var keybinds = Keybinds()
    public var themes: [Theme] = []
    public var themeTables: [TOMLTable] = []
    public var diagnostics: [Diagnostic] = []

    public init(parsing source: String, file: String? = nil) {
        do {
            table = try TOMLParser.parse(source)
        } catch {
            diagnostics = [Diagnostic(file: file, line: error.line, message: error.message)]
            return
        }
        var found: [Diagnostic] = []
        for key in table.keys {
            switch (key, table[key]) {
            case ("settings", .table(let settingsTable)?):
                let (decoded, issues) = SettingsDecoder.decode(settingsTable)
                settings = decoded
                found += issues
            case ("keybinds", .table(let keybindTable)?):
                let (decoded, issues) = Keybinds.decode(keybindTable)
                keybinds = decoded
                found += issues
            case ("theme", .array(let items)?):
                for (index, item) in items.enumerated() {
                    guard let themeTable = item.table else { continue }
                    let (theme, issues) = ThemeDecoder.decode(themeTable, index: index)
                    found += issues
                    if let theme {
                        themes.append(theme)
                        themeTables.append(themeTable)
                    }
                }
            case ("settings", _), ("keybinds", _):
                found.append(Diagnostic(line: table.line(of: key), message: "'\(key)' must be a table"))
            case ("theme", _):
                found.append(Diagnostic(line: table.line(of: key), message: "themes are written as [[theme]]"))
            default:
                found.append(Diagnostic(line: table.line(of: key), message: "unknown key '\(key)'"))
            }
        }
        diagnostics = found
            .sorted { ($0.line ?? 0) < ($1.line ?? 0) }
            .map { Diagnostic(file: file, line: $0.line, message: $0.message) }
    }
}
