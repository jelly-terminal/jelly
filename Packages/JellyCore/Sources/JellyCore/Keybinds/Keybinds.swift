public struct Keybinds: Equatable, Sendable {
    public private(set) var bindings: [KeyChord: KeyAction]

    public init(bindings: [KeyChord: KeyAction] = Self.defaultBindings) {
        self.bindings = bindings
    }

    public subscript(chord: KeyChord) -> KeyAction? {
        bindings[chord]
    }

    public func chord(for action: KeyAction) -> KeyChord? {
        bindings.filter { $0.value == action }.keys.min { $0.description < $1.description }
    }

    public func chords(for action: KeyAction) -> [KeyChord] {
        bindings.filter { $0.value == action }.keys.sorted { $0.description < $1.description }
    }

    public static let defaults = Keybinds()

    public static let defaultBindings: [KeyChord: KeyAction] = {
        var map: [String: KeyAction] = [
            "cmd+t": .tabNew,
            "cmd+w": .paneClose,
            "cmd+alt+w": .tabClose,
            "cmd+shift+left": .tabMove(.left),
            "cmd+shift+right": .tabMove(.right),
            "cmd+ctrl+=": .paneEqualize,
            "cmd+d": .splitRight,
            "cmd+shift+d": .splitDown,
            "cmd+alt+left": .paneFocus(.left),
            "cmd+alt+right": .paneFocus(.right),
            "cmd+alt+up": .paneFocus(.up),
            "cmd+alt+down": .paneFocus(.down),
            "cmd+shift+enter": .paneZoom,
            "cmd+shift+]": .tabNext,
            "cmd+shift+[": .tabPrevious,
            "cmd+shift+n": .sessionNew,
            "cmd+ctrl+]": .sessionNext,
            "cmd+ctrl+[": .sessionPrevious,
            "ctrl+tab": .sessionNext,
            "ctrl+shift+tab": .sessionPrevious,
            "cmd+0": .sidebarToggle,
            "cmd+e": .explorerToggle,
            "cmd+shift+m": .markdownPreview,
            "cmd+f": .find,
            "cmd+k": .paletteToggle,
            "cmd+shift+k": .clear,
            "cmd+c": .copy,
            "cmd+v": .paste,
            "cmd+=": .fontIncrease,
            "cmd+-": .fontDecrease,
            "cmd+shift+0": .fontReset,
            "cmd+,": .settingsOpen,
            "cmd+shift+,": .configReload,
            "cmd+up": .promptPrevious,
            "cmd+down": .promptNext,
            "cmd+shift+a": .agentNextWaiting,
            "cmd+backspace": .text("\u{15}"),
        ]
        for index in 1...9 {
            map["cmd+\(index)"] = .tabGoto(index)
            map["cmd+ctrl+\(index)"] = .sessionGoto(index)
        }
        return Dictionary(uniqueKeysWithValues: map.map { (KeyChord($0.key)!, $0.value) })
    }()

    static func decode(_ table: TOMLTable) -> (Keybinds, [Diagnostic]) {
        var bindings = defaultBindings
        var diagnostics: [Diagnostic] = []
        for key in table.keys {
            let line = table.line(of: key)
            guard let chord = KeyChord(key) else {
                diagnostics.append(Diagnostic(line: line, message: "keybinds: '\(key)' is not a valid key"))
                continue
            }
            guard case .string(let name)? = table[key], let action = KeyAction(name) else {
                diagnostics.append(Diagnostic(line: line, message: "keybinds.\(key): unknown action"))
                continue
            }
            bindings[chord] = action == .none ? nil : action
        }
        return (Keybinds(bindings: bindings), diagnostics)
    }
}
