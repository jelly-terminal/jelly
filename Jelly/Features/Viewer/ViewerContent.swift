import JellyCore

nonisolated enum ViewerContent: Sendable {
    case loading
    case markdown(MarkdownDocument)
    case text(lines: [String], tokens: [[SyntaxToken]]?, truncated: Bool)
    case unavailable(String)
}
