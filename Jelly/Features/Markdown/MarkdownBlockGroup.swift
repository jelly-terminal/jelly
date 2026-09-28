import JellyCore

struct MarkdownBlockGroup {
    let firstIndex: Int
    let paragraphs: [String]

    static func grouping(_ blocks: [MarkdownBlock]) -> [MarkdownBlockGroup] {
        var groups: [MarkdownBlockGroup] = []
        for (index, block) in blocks.enumerated() {
            guard case .paragraph(let text) = block else {
                groups.append(MarkdownBlockGroup(firstIndex: index, paragraphs: []))
                continue
            }
            if let last = groups.last, !last.paragraphs.isEmpty {
                groups[groups.count - 1] = MarkdownBlockGroup(firstIndex: last.firstIndex, paragraphs: last.paragraphs + [text])
            } else {
                groups.append(MarkdownBlockGroup(firstIndex: index, paragraphs: [text]))
            }
        }
        return groups
    }
}
