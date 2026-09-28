import JellyCore

struct MarkdownBlockGroup {
    let firstIndex: Int
    let flowing: [(index: Int, block: MarkdownBlock)]

    static func grouping(_ blocks: [MarkdownBlock]) -> [MarkdownBlockGroup] {
        var groups: [MarkdownBlockGroup] = []
        for (index, block) in blocks.enumerated() {
            guard MarkdownFlowBuilder.isFlowing(block) else {
                groups.append(MarkdownBlockGroup(firstIndex: index, flowing: []))
                continue
            }
            if let last = groups.last, !last.flowing.isEmpty {
                groups[groups.count - 1] = MarkdownBlockGroup(firstIndex: last.firstIndex, flowing: last.flowing + [(index, block)])
            } else {
                groups.append(MarkdownBlockGroup(firstIndex: index, flowing: [(index, block)]))
            }
        }
        return groups
    }
}
