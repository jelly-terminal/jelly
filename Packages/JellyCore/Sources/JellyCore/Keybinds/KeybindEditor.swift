public enum KeybindEditor {
    public static func bind(_ chord: KeyChord?, to action: KeyAction, in source: String) throws(TOMLError) -> String {
        var editor = TOMLEditor(source)
        let written = try writtenKeys(in: source)
        let current = try effectiveBindings(in: source)
        for existing in current.chords(for: action) where existing != chord {
            try unbind(existing, written: written, editor: &editor)
        }
        if let chord {
            if Keybinds.defaultBindings[chord] == action {
                if let key = written[chord] { try editor.remove(at: ["keybinds", key]) }
            } else {
                try editor.set(.string(action.name), at: ["keybinds", written[chord] ?? chord.description])
            }
        }
        return editor.source
    }

    public static func reset(_ action: KeyAction, in source: String) throws(TOMLError) -> String {
        var editor = TOMLEditor(source)
        let table = try keybindsTable(in: source)
        for key in table.keys {
            guard let chord = KeyChord(key) else { continue }
            let boundHere = table[key].flatMap(Self.action) == action
            if boundHere || Keybinds.defaultBindings[chord] == action {
                try editor.remove(at: ["keybinds", key])
            }
        }
        return editor.source
    }

    public static func resetAll(in source: String) throws(TOMLError) -> String {
        var editor = TOMLEditor(source)
        for key in try keybindsTable(in: source).keys {
            try editor.remove(at: ["keybinds", key])
        }
        return editor.source
    }

    private static func unbind(_ chord: KeyChord, written: [KeyChord: String], editor: inout TOMLEditor) throws(TOMLError) {
        if Keybinds.defaultBindings[chord] != nil {
            try editor.set(.string(KeyAction.none.name), at: ["keybinds", written[chord] ?? chord.description])
        } else if let key = written[chord] {
            try editor.remove(at: ["keybinds", key])
        }
    }

    private static func keybindsTable(in source: String) throws(TOMLError) -> TOMLTable {
        try TOMLParser.parse(source)["keybinds"]?.table ?? TOMLTable()
    }

    private static func writtenKeys(in source: String) throws(TOMLError) -> [KeyChord: String] {
        var keys: [KeyChord: String] = [:]
        for key in try keybindsTable(in: source).keys {
            if let chord = KeyChord(key) { keys[chord] = key }
        }
        return keys
    }

    private static func effectiveBindings(in source: String) throws(TOMLError) -> Keybinds {
        Keybinds.decode(try keybindsTable(in: source)).0
    }

    private static func action(_ value: TOMLValue) -> KeyAction? {
        guard case .string(let name) = value else { return nil }
        return KeyAction(name)
    }
}
