public enum KeyAction: Hashable, Sendable {
    public enum Direction: String, Sendable, CaseIterable {
        case left, right, up, down
    }

    case tabNew
    case tabClose
    case tabNext
    case tabPrevious
    case tabGoto(Int)
    case tabMove(Direction)
    case tabRename
    case splitRight
    case splitDown
    case paneClose
    case paneZoom
    case paneFocus(Direction)
    case paneEqualize
    case sessionNew
    case sessionNext
    case sessionPrevious
    case sidebarToggle
    case find
    case clear
    case copy
    case paste
    case fontIncrease
    case fontDecrease
    case fontReset
    case settingsOpen
    case configOpen
    case configReload
    case promptPrevious
    case promptNext
    case text(String)
    case none

    private static let simple: [String: KeyAction] = [
        "tab.new": .tabNew, "tab.close": .tabClose, "tab.next": .tabNext, "tab.previous": .tabPrevious,
        "tab.rename": .tabRename, "split.right": .splitRight, "split.down": .splitDown,
        "pane.close": .paneClose, "pane.zoom": .paneZoom, "pane.equalize": .paneEqualize,
        "session.new": .sessionNew, "session.next": .sessionNext, "session.previous": .sessionPrevious,
        "sidebar.toggle": .sidebarToggle, "find": .find, "clear": .clear, "copy": .copy, "paste": .paste,
        "font.increase": .fontIncrease, "font.decrease": .fontDecrease, "font.reset": .fontReset,
        "settings.open": .settingsOpen, "config.open": .configOpen, "config.reload": .configReload,
        "prompt.previous": .promptPrevious, "prompt.next": .promptNext, "none": .none,
    ]

    public init?(_ string: String) {
        if let action = Self.simple[string] {
            self = action
            return
        }
        guard let colon = string.firstIndex(of: ":") else { return nil }
        let name = string[..<colon]
        let argument = String(string[string.index(after: colon)...])
        switch name {
        case "tab.goto":
            guard let index = Int(argument), (1...9).contains(index) else { return nil }
            self = .tabGoto(index)
        case "tab.move":
            guard let direction = Direction(rawValue: argument), direction == .left || direction == .right else { return nil }
            self = .tabMove(direction)
        case "pane.focus":
            guard let direction = Direction(rawValue: argument) else { return nil }
            self = .paneFocus(direction)
        case "text":
            self = .text(Self.unescape(argument))
        default:
            return nil
        }
    }

    private static func unescape(_ string: String) -> String {
        var result = ""
        var iterator = string.makeIterator()
        while let c = iterator.next() {
            guard c == "\\", let next = iterator.next() else {
                result.append(c)
                continue
            }
            switch next {
            case "n": result.append("\n")
            case "r": result.append("\r")
            case "t": result.append("\t")
            case "e": result.append("\u{1B}")
            case "x":
                let hex = String([iterator.next(), iterator.next()].compactMap { $0 })
                if let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) {
                    result.unicodeScalars.append(scalar)
                }
            default: result.append(next)
            }
        }
        return result
    }
}
