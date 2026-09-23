public struct MarkdownList: Equatable, Sendable {
    public struct Item: Equatable, Sendable {
        public var checked: Bool?
        public var blocks: [MarkdownBlock]

        public init(checked: Bool? = nil, blocks: [MarkdownBlock]) {
            self.checked = checked
            self.blocks = blocks
        }
    }

    public var start: Int?
    public var items: [Item]

    public init(start: Int? = nil, items: [Item]) {
        self.start = start
        self.items = items
    }

    public var isOrdered: Bool { start != nil }
}
