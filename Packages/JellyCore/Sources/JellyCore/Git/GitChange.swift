public struct GitChange: Identifiable, Hashable, Sendable {
    public enum Area: Int, CaseIterable, Comparable, Sendable {
        case conflicted, staged, unstaged, untracked

        public static func < (lhs: Area, rhs: Area) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum Kind: Sendable {
        case added, modified, deleted, renamed, copied, typeChanged, untracked, conflicted
    }

    public var path: String
    public var originalPath: String?
    public var area: Area
    public var kind: Kind

    public init(path: String, originalPath: String? = nil, area: Area, kind: Kind) {
        self.path = path
        self.originalPath = originalPath
        self.area = area
        self.kind = kind
    }

    public var id: String { "\(area.rawValue):\(path)" }
}
