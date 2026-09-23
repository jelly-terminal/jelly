public struct KeyChord: Hashable, Sendable, CustomStringConvertible {
    public struct Modifiers: OptionSet, Hashable, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }

        public static let command = Modifiers(rawValue: 1 << 0)
        public static let shift = Modifiers(rawValue: 1 << 1)
        public static let option = Modifiers(rawValue: 1 << 2)
        public static let control = Modifiers(rawValue: 1 << 3)
    }

    public var modifiers: Modifiers
    public var key: String

    public init(modifiers: Modifiers, key: String) {
        self.modifiers = modifiers
        self.key = key
    }

    public init?(_ string: String) {
        var parts = string.lowercased().split(separator: "+", omittingEmptySubsequences: false).map(String.init)
        if string.hasSuffix("++") {
            parts.removeLast(2)
            parts.append("+")
        }
        guard let last = parts.popLast(), !last.isEmpty else { return nil }
        var modifiers: Modifiers = []
        for part in parts {
            switch part {
            case "cmd", "command", "super": modifiers.insert(.command)
            case "shift": modifiers.insert(.shift)
            case "alt", "opt", "option": modifiers.insert(.option)
            case "ctrl", "control": modifiers.insert(.control)
            default: return nil
            }
        }
        guard let key = Self.normalizedKey(last) else { return nil }
        self.init(modifiers: modifiers, key: key)
    }

    static let namedKeys: [String: String] = [
        "enter": "enter", "return": "enter", "tab": "tab", "space": "space",
        "esc": "escape", "escape": "escape", "backspace": "backspace", "delete": "delete",
        "left": "left", "right": "right", "up": "up", "down": "down",
        "home": "home", "end": "end", "pageup": "pageup", "pagedown": "pagedown",
    ]

    private static func normalizedKey(_ key: String) -> String? {
        if let named = namedKeys[key] { return named }
        if key.count == 1 { return key }
        if key.hasPrefix("f"), let number = Int(key.dropFirst()), (1...20).contains(number) { return key }
        return nil
    }

    public var description: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("ctrl") }
        if modifiers.contains(.option) { parts.append("alt") }
        if modifiers.contains(.shift) { parts.append("shift") }
        if modifiers.contains(.command) { parts.append("cmd") }
        return (parts + [key]).joined(separator: "+")
    }
}
