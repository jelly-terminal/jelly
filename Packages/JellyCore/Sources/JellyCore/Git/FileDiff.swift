public struct FileDiff: Equatable, Sendable {
    public struct Hunk: Equatable, Sendable {
        public var header: String
        public var oldStart: Int
        public var newStart: Int
        public var lines: [Line] = []
    }

    public struct Line: Equatable, Sendable {
        public enum Kind: Sendable {
            case context, added, removed
        }

        public var kind: Kind
        public var text: String
        public var oldNumber: Int?
        public var newNumber: Int?
        public var missingNewline = false
    }

    public var hunks: [Hunk] = []
    public var isBinary = false

    public init() {}

    public var additions: Int {
        hunks.reduce(0) { $0 + $1.lines.count { $0.kind == .added } }
    }

    public var deletions: Int {
        hunks.reduce(0) { $0 + $1.lines.count { $0.kind == .removed } }
    }
}
