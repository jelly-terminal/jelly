import Foundation
import JellyCore

enum ViewerLoader {
    nonisolated static let textLimit = 2_000_000

    @concurrent
    nonisolated static func load(_ url: URL) async -> ViewerContent {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .unavailable("Couldn’t open this file.") }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: textLimit + 1) else { return .unavailable("Couldn’t read this file.") }
        let truncated = data.count > textLimit
        let bytes = data.prefix(textLimit)
        guard !bytes.contains(0), let text = String(data: bytes, encoding: .utf8) ?? String(data: bytes.dropLast(3), encoding: .utf8) else {
            return .unavailable("This file isn’t text.")
        }
        let isMarkdown = ["md", "markdown", "mdown", "mkd"].contains(url.pathExtension.lowercased())
        if isMarkdown, !truncated { return .markdown(MarkdownDocument(text)) }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count <= highlightLineLimit, let language = language(for: url) else {
            return .text(lines: lines, tokens: nil, truncated: truncated)
        }
        let tokens = SyntaxHighlighter.lines(of: text, tokens: SyntaxHighlighter.tokens(in: text, language: language))
        return .text(lines: lines, tokens: tokens, truncated: truncated)
    }

    nonisolated static let highlightLineLimit = 50_000

    private nonisolated static func language(for url: URL) -> SyntaxLanguage? {
        let name = url.lastPathComponent.lowercased()
        if name == "dockerfile" || name.hasPrefix("dockerfile.") { return SyntaxLanguage.named("docker") }
        if name == "makefile" || name == "gnumakefile" { return SyntaxLanguage.named("make") }
        if [".zshrc", ".bashrc", ".bash_profile", ".zprofile", ".profile", ".envrc"].contains(name) { return SyntaxLanguage.named("shell") }
        return SyntaxLanguage.named(url.pathExtension)
    }
}
