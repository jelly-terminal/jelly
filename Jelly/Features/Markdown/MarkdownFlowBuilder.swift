import AppKit
import JellyCore
import SwiftUI

struct MarkdownFlowBuilder {
    private struct Context {
        var indent: CGFloat = 0
        var opacity: CGFloat = 1
        var listDepth = 0
    }

    let style: MarkdownStyle
    private let text = NSMutableAttributedString()
    private var anchors: [Int: NSRange] = [:]
    private var decorations: [TextDecoration] = []
    private var codeBlocks: [MarkdownFlow.CodeBlock] = []
    private var pendingSpacing: CGFloat = 0
    private var separatorAttributes: [NSAttributedString.Key: Any] = [:]

    static let markerWidth = Metrics.markdownListMarkerWidth
    static let markerGap: CGFloat = 8
    static let quoteIndent: CGFloat = 15

    init(style: MarkdownStyle) {
        self.style = style
    }

    static func isFlowing(_ block: MarkdownBlock) -> Bool {
        switch block {
        case .heading, .paragraph, .code, .rule: true
        case .list(let list): list.items.allSatisfy { $0.blocks.allSatisfy(isFlowing) }
        case .quote(let blocks): blocks.allSatisfy(isFlowing)
        default: false
        }
    }

    static func build(_ blocks: [(index: Int, block: MarkdownBlock)], style: MarkdownStyle) -> MarkdownFlow {
        var builder = MarkdownFlowBuilder(style: style)
        for (index, block) in blocks {
            builder.append(block, context: Context(), anchor: index, spacing: Metrics.markdownBlockSpacing)
        }
        return MarkdownFlow(text: builder.text, anchors: builder.anchors, codeBlocks: builder.codeBlocks, decorations: builder.decorations)
    }

    private mutating func append(_ block: MarkdownBlock, context: Context, anchor: Int?, spacing: CGFloat) {
        switch block {
        case .heading(let level, let content):
            let range = appendParagraph(inline(content, font: headingFont(level), context: context), context: context, spacing: spacing + (level <= 2 ? 8 : 4))
            if let anchor { anchors[anchor] = range }
            if level <= 2 {
                decorations.append(.underline(range, color: NSColor(style.faint)))
                pendingSpacing = 7
            }
        case .paragraph(let content):
            appendParagraph(inline(content, font: bodyFont, context: context), context: context, spacing: spacing)
        case .code(let language, let content):
            appendCode(content, language: language, context: context, spacing: spacing)
        case .rule:
            let range = appendParagraph(NSAttributedString(string: "\u{200B}", attributes: [.font: bodyFont]), context: context, spacing: spacing)
            decorations.append(.rule(range, color: NSColor(style.faint)))
        case .list(let list):
            appendList(list, context: context, spacing: spacing)
        case .quote(let blocks):
            let start = text.length
            var inner = context
            inner.indent += Self.quoteIndent
            inner.opacity *= 0.8
            for (offset, child) in blocks.enumerated() {
                append(child, context: inner, anchor: nil, spacing: offset == 0 ? spacing : Metrics.markdownBlockSpacing)
            }
            let range = NSRange(location: start, length: text.length - start)
            decorations.append(.bar(range, x: context.indent, width: 3, color: NSColor(style.accent.opacity(0.6))))
        default:
            break
        }
    }

    private mutating func appendList(_ list: MarkdownList, context: Context, spacing: CGFloat) {
        let textIndent = context.indent + Self.markerWidth + Self.markerGap
        for (index, item) in list.items.enumerated() {
            var inner = context
            inner.indent = textIndent
            inner.listDepth += 1
            if item.checked == true { inner.opacity *= 0.6 }
            let itemSpacing = index == 0 ? spacing : 6
            let marker = marker(for: item, in: list, at: index, depth: context.listDepth, opacity: inner.opacity)
            guard case .paragraph(let content)? = item.blocks.first else {
                appendParagraph(marker, context: inner, spacing: itemSpacing, markerIndent: context.indent)
                for block in item.blocks { append(block, context: inner, anchor: nil, spacing: 8) }
                continue
            }
            let line = NSMutableAttributedString(attributedString: marker)
            line.append(inline(content, font: bodyFont, context: inner))
            appendParagraph(line, context: inner, spacing: itemSpacing, markerIndent: context.indent)
            for block in item.blocks.dropFirst() { append(block, context: inner, anchor: nil, spacing: 8) }
        }
    }

    private mutating func appendCode(_ content: String, language: String?, context: Context, spacing: CGFloat) {
        let padding = Metrics.markdownCodePadding
        let font = style.codeFont.withSize(Metrics.markdownCodeSize)
        var inner = context
        inner.indent += padding
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let tokens = language.flatMap(SyntaxLanguage.named).map { SyntaxHighlighter.lines(of: content, tokens: SyntaxHighlighter.tokens(in: content, language: $0)) }
        var start: Int?
        for (index, line) in lines.enumerated() {
            let highlighted = code(line, tokens: tokens.flatMap { $0.indices.contains(index) ? $0[index] : nil } ?? [], font: font, opacity: context.opacity)
            let range = appendParagraph(highlighted, context: inner, spacing: index == 0 ? spacing + padding : 0, font: font, lineSpacing: 3, tailIndent: -padding)
            if start == nil { start = range.location }
        }
        let range = NSRange(location: start ?? text.length, length: text.length - (start ?? text.length))
        decorations.append(.box(range, x: context.indent, padding: padding, cornerRadius: Metrics.markdownCornerRadius, color: NSColor(style.fill)))
        codeBlocks.append(MarkdownFlow.CodeBlock(range: range, language: language, text: content))
        pendingSpacing = padding
    }

    private func code(_ line: String, tokens: [SyntaxToken], font: NSFont, opacity: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(string: line, attributes: [.font: font, .foregroundColor: NSColor(style.text).withAlphaComponent(opacity)])
        let utf8 = Array(line.utf8)
        for token in tokens where token.range.upperBound <= utf8.count {
            let location = String(decoding: utf8[..<token.range.lowerBound], as: UTF8.self).utf16.count
            let length = String(decoding: utf8[token.range], as: UTF8.self).utf16.count
            result.addAttribute(.foregroundColor, value: NSColor(style.color(for: token.kind)).withAlphaComponent(opacity), range: NSRange(location: location, length: length))
        }
        return result
    }

    private func marker(for item: MarkdownList.Item, in list: MarkdownList, at index: Int, depth: Int, opacity: CGFloat) -> NSAttributedString {
        let color = NSColor(style.secondary).withAlphaComponent(0.6 * opacity)
        let result = NSMutableAttributedString(string: "\t")
        if let checked = item.checked {
            let symbol = checked ? "checkmark.square.fill" : "square"
            let tint = checked ? NSColor(style.accent) : color
            let configuration = NSImage.SymbolConfiguration(pointSize: Metrics.markdownBodySize - 1, weight: .regular)
                .applying(.init(paletteColors: [tint]))
            if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: checked ? "Done" : "To do")?.withSymbolConfiguration(configuration) {
                let attachment = NSTextAttachment()
                attachment.image = image
                attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
                result.append(NSAttributedString(attachment: attachment))
            }
        } else {
            let label = list.start.map { "\($0 + index)." } ?? (depth == 0 ? "•" : depth == 1 ? "◦" : "▪︎")
            let font = list.start == nil ? bodyFont : NSFont.monospacedDigitSystemFont(ofSize: Metrics.markdownBodySize, weight: .regular)
            result.append(NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: color]))
        }
        result.append(NSAttributedString(string: "\t", attributes: [.font: bodyFont]))
        return result
    }

    @discardableResult
    private mutating func appendParagraph(
        _ content: NSAttributedString,
        context: Context,
        spacing: CGFloat,
        markerIndent: CGFloat? = nil,
        font: NSFont? = nil,
        lineSpacing: CGFloat = Metrics.markdownLineSpacing,
        tailIndent: CGFloat = 0
    ) -> NSRange {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing
        paragraph.headIndent = context.indent
        paragraph.firstLineHeadIndent = markerIndent ?? context.indent
        paragraph.tailIndent = tailIndent
        paragraph.paragraphSpacingBefore = text.length == 0 ? 0 : spacing + pendingSpacing
        if let markerIndent {
            paragraph.tabStops = [
                NSTextTab(textAlignment: .right, location: markerIndent + Self.markerWidth),
                NSTextTab(textAlignment: .left, location: context.indent),
            ]
        }
        pendingSpacing = 0
        if text.length > 0 { text.append(NSAttributedString(string: "\n", attributes: separatorAttributes)) }
        let start = text.length
        text.append(content)
        let range = NSRange(location: start, length: text.length - start)
        text.addAttribute(.paragraphStyle, value: paragraph, range: range)
        separatorAttributes = [.font: font ?? bodyFont, .paragraphStyle: paragraph]
        return range
    }

    private var bodyFont: NSFont {
        .systemFont(ofSize: Metrics.markdownBodySize)
    }

    private func headingFont(_ level: Int) -> NSFont {
        let sizes: [CGFloat] = [26, 21, 17, 15, 14, 13]
        let size = sizes[min(max(level, 1), sizes.count) - 1]
        return .systemFont(ofSize: size, weight: level <= 2 ? .bold : .semibold)
    }

    private func inline(_ markdown: String, font: NSFont, context: Context) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let color = NSColor(style.text).withAlphaComponent(context.opacity)
        let parsed = style.inline(markdown)
        for run in parsed.runs {
            let piece = String(parsed[run.range].characters).replacing("\n", with: "\u{2028}")
            let intent = run.inlinePresentationIntent ?? []
            var runFont = font
            var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
            if intent.contains(.code) {
                runFont = style.codeFont.withSize(font.pointSize - 1)
                attributes[.backgroundColor] = NSColor(style.fill)
            }
            if intent.contains(.stronglyEmphasized) { runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .boldFontMask) }
            if intent.contains(.emphasized) { runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .italicFontMask) }
            if intent.contains(.strikethrough) { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if let link = run.link { attributes[.link] = link }
            attributes[.font] = runFont
            result.append(NSAttributedString(string: piece, attributes: attributes))
        }
        return result
    }
}
