public struct QuickTerminalSettings: Equatable, Sendable {
    public var enabled = true
    public var hotkey: KeyChord? = KeyChord(modifiers: .control, key: "space")

    public init() {}
}
