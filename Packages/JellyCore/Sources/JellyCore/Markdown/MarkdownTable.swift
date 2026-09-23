public struct MarkdownTable: Equatable, Sendable {
    public enum Alignment: Sendable {
        case leading, center, trailing
    }

    public var alignments: [Alignment]
    public var header: [String]
    public var rows: [[String]]

    public init(alignments: [Alignment], header: [String], rows: [[String]]) {
        self.alignments = alignments
        self.header = header
        self.rows = rows
    }
}
