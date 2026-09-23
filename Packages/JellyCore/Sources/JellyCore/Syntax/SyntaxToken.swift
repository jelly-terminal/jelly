public struct SyntaxToken: Equatable, Sendable {
    public enum Kind: Sendable {
        case keyword, string, comment, number, literal, type, function, variable, tag, inserted, deleted
    }

    public var kind: Kind
    public var range: Range<Int>

    public init(_ kind: Kind, _ range: Range<Int>) {
        self.kind = kind
        self.range = range
    }
}
