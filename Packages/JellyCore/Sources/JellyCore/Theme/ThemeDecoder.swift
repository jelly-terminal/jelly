enum ThemeDecoder {
    static func decode(_ table: TOMLTable, index: Int) -> (Theme?, [Diagnostic]) {
        var reader = TableReader(table, path: "theme[\(index)]")
        var failed = false

        func color(_ key: String, required: Bool) -> ThemeColor? {
            guard let hex = reader.string(key) else {
                if required, table[key] == nil {
                    reader.missing(key)
                }
                if required { failed = true }
                return nil
            }
            guard let color = ThemeColor(hex: hex) else {
                reader.report(key, "'\(hex)' is not a hex color (#rgb, #rrggbb or #rrggbbaa)")
                if required { failed = true }
                return nil
            }
            return color
        }

        let id = reader.string("id")
        if id == nil {
            reader.missing("id")
        }
        let name = reader.string("name")
        let appearance = reader.choice("appearance", ["dark": Theme.Appearance.dark, "light": .light])
        let background = color("background", required: true)
        let foreground = color("foreground", required: true)

        var palette: [ThemeColor] = []
        if let hexes = reader.strings("palette") {
            if hexes.count != 16 {
                reader.report("palette", "needs exactly 16 colors, found \(hexes.count)")
                failed = true
            }
            for hex in hexes {
                guard let parsed = ThemeColor(hex: hex) else {
                    reader.report("palette", "'\(hex)' is not a hex color")
                    failed = true
                    continue
                }
                palette.append(parsed)
            }
        } else {
            if table["palette"] == nil {
                reader.missing("palette")
            }
            failed = true
        }

        let cursor = color("cursor", required: false)
        let cursorText = color("cursor-text", required: false)
        let selection = color("selection", required: false)
        let selectionText = color("selection-text", required: false)
        let accent = color("accent", required: false)
        let diagnostics = reader.finished()

        guard !failed, let id, let background, let foreground, palette.count == 16 else {
            return (nil, diagnostics)
        }
        let theme = Theme(
            id: id,
            name: name ?? id,
            appearance: appearance,
            background: background,
            foreground: foreground,
            palette: palette,
            cursor: cursor,
            cursorText: cursorText,
            selection: selection,
            selectionText: selectionText,
            accent: accent
        )
        return (theme, diagnostics)
    }
}
