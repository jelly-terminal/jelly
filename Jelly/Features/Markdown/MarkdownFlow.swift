import AppKit

struct MarkdownFlow {
    struct CodeBlock {
        let range: NSRange
        let language: String?
        let text: String
    }

    let text: NSAttributedString
    let anchors: [Int: NSRange]
    let codeBlocks: [CodeBlock]
    let decorations: [TextDecoration]
}
