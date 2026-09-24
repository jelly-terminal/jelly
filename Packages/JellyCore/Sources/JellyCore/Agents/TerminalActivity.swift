public struct TerminalActivity: Equatable, Sendable {
    public var lastOutput: ContinuousClock.Instant?
    public var lastInput: ContinuousClock.Instant?
    public var lastAlert: ContinuousClock.Instant?
    public var alertMessage: String?

    public init() {}

    public mutating func alert(_ message: String?, at instant: ContinuousClock.Instant) {
        lastAlert = instant
        alertMessage = message
    }
}
