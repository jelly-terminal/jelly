import AppKit
import JellyCore
import SwiftUI

struct MarkdownStyle {
    let theme: Theme
    let codeFont: NSFont
    let baseURL: URL

    var text: Color { Color(theme.foreground) }
    var secondary: Color { Color(theme.foreground).opacity(0.6) }
    var faint: Color { Color(theme.foreground).opacity(0.12) }
    var fill: Color { Color(theme.foreground).opacity(0.05) }
    var accent: Color { Color(theme.accent) }

    var bodyFont: Font { .system(size: Metrics.markdownBodySize) }

    func code(size: CGFloat) -> Font {
        Font(codeFont.withSize(size))
    }

    func headingFont(_ level: Int) -> Font {
        let sizes: [CGFloat] = [26, 21, 17, 15, 14, 13]
        let size = sizes[min(max(level, 1), sizes.count) - 1]
        return .system(size: size, weight: level <= 2 ? .bold : .semibold)
    }

    func highlighted(_ text: String, tokens: [SyntaxToken]) -> AttributedString {
        let bytes = Array(text.utf8)
        var result = AttributedString()
        var cursor = 0
        for token in tokens where token.range.lowerBound >= cursor && token.range.upperBound <= bytes.count {
            if token.range.lowerBound > cursor {
                result += AttributedString(String(decoding: bytes[cursor..<token.range.lowerBound], as: UTF8.self))
            }
            var piece = AttributedString(String(decoding: bytes[token.range], as: UTF8.self))
            piece.foregroundColor = color(for: token.kind)
            result += piece
            cursor = token.range.upperBound
        }
        if cursor < bytes.count {
            result += AttributedString(String(decoding: bytes[cursor...], as: UTF8.self))
        }
        return result
    }

    func color(for kind: SyntaxToken.Kind) -> Color {
        let palette = theme.palette
        return switch kind {
        case .keyword, .tag: Color(palette[5])
        case .string, .inserted: Color(palette[2])
        case .comment: Color(palette[8])
        case .number, .literal: Color(palette[3])
        case .type: Color(palette[6])
        case .function: Color(palette[4])
        case .variable, .deleted: Color(palette[1])
        }
    }

    func inline(_ markdown: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        var attributed = (try? AttributedString(markdown: markdown, options: options, baseURL: baseURL)) ?? AttributedString(markdown)
        for run in attributed.runs {
            if run.inlinePresentationIntent?.contains(.code) == true {
                attributed[run.range].font = code(size: Metrics.markdownBodySize - 1)
                attributed[run.range].backgroundColor = fill
            }
            if run.link != nil {
                attributed[run.range].foregroundColor = accent
            }
        }
        return attributed
    }
}
