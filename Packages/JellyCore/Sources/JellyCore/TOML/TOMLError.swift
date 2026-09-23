public struct TOMLError: Error, Equatable, Sendable, CustomStringConvertible {
    public var line: Int
    public var message: String

    public var description: String { "line \(line): \(message)" }
}
