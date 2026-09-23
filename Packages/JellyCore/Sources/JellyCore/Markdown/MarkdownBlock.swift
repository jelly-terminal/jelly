public indirect enum MarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case code(language: String?, text: String)
    case quote([MarkdownBlock])
    case list(MarkdownList)
    case table(MarkdownTable)
    case image(alt: String, source: String)
    case html(String)
    case rule
}
