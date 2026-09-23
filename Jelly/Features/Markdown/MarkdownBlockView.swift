import AppKit
import JellyCore
import SwiftUI

struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let style: MarkdownStyle
    let depth: Int

    var body: some View {
        switch block {
        case .heading(let level, let text):
            VStack(alignment: .leading, spacing: 6) {
                Text(style.inline(text))
                    .font(style.headingFont(level))
                    .foregroundStyle(style.text)
                if level <= 2 {
                    Rectangle().fill(style.faint).frame(height: 1)
                }
            }
            .padding(.top, level <= 2 ? 8 : 4)
            .textSelection(.enabled)
        case .paragraph(let text):
            Text(style.inline(text))
                .font(style.bodyFont)
                .foregroundStyle(style.text)
                .lineSpacing(Metrics.markdownLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        case .code(let language, let text):
            MarkdownCodeBlock(language: language, text: text, style: style)
        case .quote(let blocks):
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 1.5).fill(style.accent.opacity(0.6)).frame(width: 3)
                VStack(alignment: .leading, spacing: Metrics.markdownBlockSpacing) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, child in
                        MarkdownBlockView(block: child, style: style, depth: depth)
                    }
                }
                .opacity(0.8)
            }
            .fixedSize(horizontal: false, vertical: true)
        case .list(let list):
            MarkdownListView(list: list, style: style, depth: depth)
        case .table(let table):
            MarkdownTableView(table: table, style: style)
        case .image(let alt, let source):
            MarkdownImage(alt: alt, source: source, style: style)
        case .html(let html):
            MarkdownHTMLView(html: html, style: style)
        case .rule:
            Rectangle().fill(style.faint).frame(height: 1).padding(.vertical, 4)
        }
    }
}
