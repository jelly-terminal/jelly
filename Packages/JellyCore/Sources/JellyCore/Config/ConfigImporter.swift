public enum ConfigImporter {
    public static func plan(importing source: String, file: String? = nil, currentConfig: String, existingThemeIDs: Set<String>) -> ImportPlan {
        var plan = ImportPlan()
        let incoming = ConfigDocument(parsing: source, file: file)
        plan.diagnostics = incoming.diagnostics

        let current: TOMLTable
        do {
            current = try TOMLParser.parse(currentConfig)
        } catch {
            plan.canApply = false
            plan.diagnostics.append(Diagnostic(file: "jelly.toml", line: error.line, message: "fix this error before importing: \(error.message)"))
            return plan
        }

        for section in ["settings", "keybinds"] {
            guard let table = incoming.table[section]?.table else { continue }
            let changes = leaves(of: table, prefix: [section]).compactMap { path, value -> ImportPlan.Change? in
                let old = current.value(at: path)
                return old == value ? nil : ImportPlan.Change(path: path, old: old, new: value)
            }
            if section == "settings" { plan.settingChanges = changes } else { plan.keybindChanges = changes }
        }

        plan.themes = zip(incoming.themes, incoming.themeTables).map { theme, table in
            ImportPlan.ThemeImport(theme: theme, table: table, replaces: existingThemeIDs.contains(theme.id))
        }
        return plan
    }

    public static func apply(_ plan: ImportPlan, to currentConfig: String) throws(TOMLError) -> String {
        var editor = TOMLEditor(currentConfig)
        for change in plan.settingChanges + plan.keybindChanges {
            try editor.set(change.new, at: change.path)
        }
        return editor.source
    }

    public static func themeFileContents(_ table: TOMLTable) -> String {
        "[[theme]]\n" + TOMLWriter.tableBody(table)
    }

    private static func leaves(of table: TOMLTable, prefix: [String]) -> [([String], TOMLValue)] {
        table.keys.flatMap { key -> [([String], TOMLValue)] in
            guard let value = table[key] else { return [] }
            if case .table(let child) = value {
                return leaves(of: child, prefix: prefix + [key])
            }
            return [(prefix + [key], value)]
        }
    }
}

extension TOMLTable {
    func value(at path: [String]) -> TOMLValue? {
        var table = self
        for key in path.dropLast() {
            guard case .table(let child)? = table[key] else { return nil }
            table = child
        }
        return path.last.flatMap { table[$0] }
    }
}
