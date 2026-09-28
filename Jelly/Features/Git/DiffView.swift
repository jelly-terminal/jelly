import AppKit
import JellyCore
import SwiftUI

struct DiffView: View {
    let document: DiffDocument
    let style: MarkdownStyle
    let hunkMove: ViewerModel.HunkMove

    @State private var viewportWidth: CGFloat = 0
    @State private var position = ScrollPosition()
    @State private var scroll = ScrollOffset()

    private let lineHeight = Metrics.codeLineHeight

    var body: some View {
        let numberWidth = CGFloat(max(String(largestLineNumber).count, 2)) * Metrics.markdownCodeSize * 0.62
        ScrollView([.vertical, .horizontal]) {
            HStack(alignment: .top, spacing: 0) {
                Text(gutter(\.oldNumber))
                    .frame(width: numberWidth, alignment: .trailing)
                Text(gutter(\.newNumber))
                    .frame(width: numberWidth, alignment: .trailing)
                    .padding(.leading, Metrics.diffGutterSpacing)
                Text(markers)
                    .padding(.horizontal, Metrics.diffGutterSpacing)
                Text(content)
                    .foregroundStyle(style.text)
                    .fixedSize()
                    .textSelection(.enabled)
            }
            .foregroundStyle(style.secondary.opacity(0.7))
            .font(style.code(size: Metrics.markdownCodeSize))
            .padding(.vertical, Metrics.diffVerticalPadding)
            .padding(.horizontal, Metrics.diffPadding)
            .frame(minWidth: viewportWidth, alignment: .leading)
            .background(alignment: .topLeading) { tints }
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { scroll.y = $1 }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
        .onChange(of: hunkMove) { _, move in jump(by: move.offset) }
    }

    private var largestLineNumber: Int {
        document.rows.last { $0.newNumber != nil || $0.oldNumber != nil }.map { max($0.oldNumber ?? 0, $0.newNumber ?? 0) } ?? 0
    }

    private var tints: some View {
        Canvas { context, size in
            for (index, row) in document.rows.enumerated() {
                guard let color = tint(for: row.kind) else { continue }
                let rect = CGRect(x: 0, y: Metrics.diffVerticalPadding + CGFloat(index) * lineHeight, width: size.width, height: lineHeight)
                context.fill(Path(rect), with: .color(color))
            }
        }
    }

    private func tint(for kind: DiffDocument.Row.Kind) -> Color? {
        switch kind {
        case .added: Color(style.theme.palette[2]).opacity(0.14)
        case .removed: Color(style.theme.palette[1]).opacity(0.14)
        case .hunk: style.accent.opacity(0.08)
        case .context: nil
        }
    }

    private var paragraphStyle: NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        return paragraph
    }

    private func gutter(_ number: KeyPath<DiffDocument.Row, Int?>) -> AttributedString {
        var result = AttributedString(document.rows.map { $0[keyPath: number].map(String.init) ?? "" }.joined(separator: "\n"))
        result.paragraphStyle = paragraphStyle
        return result
    }

    private var markers: AttributedString {
        var result = AttributedString()
        for (index, row) in document.rows.enumerated() {
            var marker = AttributedString(row.kind == .added ? "+" : row.kind == .removed ? "-" : " ")
            if let color = tint(for: row.kind), row.kind != .hunk { marker.foregroundColor = color.opacity(1) }
            result += marker
            if index < document.rows.count - 1 { result += AttributedString("\n") }
        }
        result.paragraphStyle = paragraphStyle
        return result
    }

    private var content: AttributedString {
        var result = AttributedString()
        for (index, row) in document.rows.enumerated() {
            result += line(row)
            if index < document.rows.count - 1 { result += AttributedString("\n") }
        }
        result.paragraphStyle = paragraphStyle
        return result
    }

    private func line(_ row: DiffDocument.Row) -> AttributedString {
        guard !row.text.isEmpty else { return AttributedString() }
        guard row.kind != .hunk else {
            var header = AttributedString(row.text)
            header.foregroundColor = style.secondary
            return header
        }
        return row.tokens.isEmpty ? AttributedString(row.text) : style.highlighted(row.text, tokens: row.tokens)
    }

    private func jump(by offset: Int) {
        let top = (scroll.y - Metrics.diffVerticalPadding) / lineHeight
        let hunks = document.hunkRows
        let target = offset > 0 ? hunks.first { CGFloat($0) > top + 0.5 } : hunks.last { CGFloat($0) < top - 0.5 }
        guard let target else {
            NSSound.beep()
            return
        }
        withAnimation(.smooth(duration: 0.2)) {
            position.scrollTo(y: Metrics.diffVerticalPadding + CGFloat(target) * lineHeight)
        }
    }
}
