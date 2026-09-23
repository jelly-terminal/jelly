public struct TOMLTable: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public var value: TOMLValue
        public var line: Int
        public var valueRange: Range<Int>?
    }

    public private(set) var keys: [String] = []
    private var entries: [String: Entry] = [:]
    public var line = 0
    var isHeaderDefined = false
    var blockEnd: Int?

    public init() {}

    public subscript(key: String) -> TOMLValue? {
        entries[key]?.value
    }

    public func entry(_ key: String) -> Entry? {
        entries[key]
    }

    public func line(of key: String) -> Int? {
        entries[key]?.line
    }

    public var isEmpty: Bool { keys.isEmpty }

    public mutating func set(_ key: String, _ value: TOMLValue, line: Int = 0, valueRange: Range<Int>? = nil) {
        if entries[key] == nil { keys.append(key) }
        entries[key] = Entry(value: value, line: line, valueRange: valueRange)
    }

    public func removing(_ key: String) -> TOMLTable {
        var table = TOMLTable()
        for other in keys where other != key {
            if let entry = entries[other] { table.set(other, entry.value, line: entry.line, valueRange: entry.valueRange) }
        }
        return table
    }

    mutating func modifyEntry(_ key: String, _ body: (inout Entry) -> Void) {
        guard var entry = entries[key] else { return }
        body(&entry)
        entries[key] = entry
    }

    public static func == (lhs: TOMLTable, rhs: TOMLTable) -> Bool {
        lhs.keys == rhs.keys && lhs.keys.allSatisfy { lhs.entries[$0]?.value == rhs.entries[$0]?.value }
    }
}
