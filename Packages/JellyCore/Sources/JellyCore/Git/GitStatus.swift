public struct GitStatus: Equatable, Sendable {
    public var branch: String?
    public var commit: String?
    public var upstream: String?
    public var ahead = 0
    public var behind = 0
    public var changes: [GitChange] = []

    public init() {}
}
