public struct Diagnostic: Equatable, Sendable, CustomStringConvertible {
    public var file: String?
    public var line: Int?
    public var message: String

    public init(file: String? = nil, line: Int? = nil, message: String) {
        self.file = file
        self.line = line
        self.message = message
    }

    public var description: String {
        let location = [file, line.map { "line \($0)" }].compactMap { $0 }.joined(separator: ", ")
        return location.isEmpty ? message : "\(location): \(message)"
    }
}
