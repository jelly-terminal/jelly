import AppKit
import JellyCore

extension KeyChord {
    private static let namedKeyCodes: [UInt16: String] = [
        36: "enter", 76: "enter", 48: "tab", 49: "space", 51: "backspace", 117: "delete", 53: "escape",
        123: "left", 124: "right", 125: "down", 126: "up",
        115: "home", 119: "end", 116: "pageup", 121: "pagedown",
        122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6", 98: "f7", 100: "f8",
        101: "f9", 109: "f10", 103: "f11", 111: "f12",
    ]

    init?(event: NSEvent) {
        var modifiers: Modifiers = []
        let flags = event.modifierFlags
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }

        if let named = Self.namedKeyCodes[event.keyCode] {
            self.init(modifiers: modifiers, key: named)
            return
        }
        guard let base = event.characters(byApplyingModifiers: []), base.count == 1 else { return nil }
        self.init(modifiers: modifiers, key: base.lowercased())
    }

    var keyEquivalent: (key: String, modifiers: NSEvent.ModifierFlags) {
        var flags: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.control) { flags.insert(.control) }
        let special: [String: Int] = [
            "enter": 0x0D, "tab": 0x09, "space": 0x20, "backspace": 0x08, "escape": 0x1B,
            "left": NSLeftArrowFunctionKey, "right": NSRightArrowFunctionKey,
            "up": NSUpArrowFunctionKey, "down": NSDownArrowFunctionKey,
            "home": NSHomeFunctionKey, "end": NSEndFunctionKey,
            "pageup": NSPageUpFunctionKey, "pagedown": NSPageDownFunctionKey, "delete": NSDeleteFunctionKey,
        ]
        if let code = special[key], let scalar = Unicode.Scalar(code) {
            return (String(Character(scalar)), flags)
        }
        return (key, flags)
    }
}
