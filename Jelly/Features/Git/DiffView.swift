import AppKit
import JellyCore
import SwiftUI

struct DiffView: View {
    let document: DiffDocument
    let style: MarkdownStyle
    let hunkMove: ViewerModel.HunkMove

    @State private var viewportSize: CGSize = .zero
    @State private var position = ScrollPosition()
    @State private var scroll = ScrollOffset()

    private let lineHeight = Metrics.codeLineHeight

    var body: some View {
        let font = style.codeFont.withSize(Metrics.markdownCodeSize)
        ScrollView([.vertical, .horizontal]) {
            HStack(alignment: .top, spacing: 0) {
                SelectableText(text: gutter(\.oldNumber, font: font), wraps: false, isSelectable: false)
                    .frame(width: numberWidth(font), alignment: .trailing)
                SelectableText(text: gutter(\.newNumber, font: font), wraps: false, isSelectable: false)
                    .frame(width: numberWidth(font), alignment: .trailing)
                    .padding(.leading, Metrics.diffGutterSpacing)
                SelectableText(text: markers(font: font), wraps: false, isSelectable: false)
                    .padding(.horizontal, Metrics.diffGutterSpacing)
                SelectableText(text: content(font: font), wraps: false)
            }
            .padding(.vertical, Metrics.diffVerticalPadding)
            .padding(.horizontal, Metrics.diffPadding)
            .frame(minWidth: viewportSize.width, minHeight: viewportSize.height, alignment: .topLeading)
            .background(alignment: .topLeading) { tints }
        }
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { scroll.y = $1 }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
        .onChange(of: hunkMove) { _, move in jump(by: move.offset) }
    }

    private func numberWidth(_ font: NSFont) -> CGFloat {
        let largest = document.rows.reduce(0) { max($0, $1.oldNumber ?? 0, $1.newNumber ?? 0) }
        let digits = String(repeating: "0", count: max(String(largest).count, 2))
        return ceil(NSAttributedString(string: digits, attributes: [.font: font]).size().width)
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

    private func lines(_ lines: [NSAttributedString], font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byClipping
        let natural = NSLayoutManager().defaultLineHeight(for: font)
        let result = NSMutableAttributedString()
        for (index, line) in lines.enumerated() {
            if index > 0 { result.append(NSAttributedString(string: "\n")) }
            result.append(line)
        }
        let whole = NSRange(location: 0, length: result.length)
        result.addAttributes([.font: font, .paragraphStyle: paragraph, .baselineOffset: max(lineHeight - natural, 0) / 2], range: whole)
        result.enumerateAttribute(.foregroundColor, in: whole) { value, range, _ in
            if value == nil { result.addAttribute(.foregroundColor, value: color, range: range) }
        }
        return result
    }

    private func gutter(_ number: KeyPath<DiffDocument.Row, Int?>, font: NSFont) -> NSAttributedString {
        let numbers = document.rows.map { NSAttributedString(string: $0[keyPath: number].map(String.init) ?? "") }
        return lines(numbers, font: font, color: NSColor(style.secondary.opacity(0.7)), alignment: .right)
    }

    private func markers(font: NSFont) -> NSAttributedString {
        let added = NSColor(Color(style.theme.palette[2]))
        let removed = NSColor(Color(style.theme.palette[1]))
        let markers = document.rows.map { row -> NSAttributedString in
            switch row.kind {
            case .added: NSAttributedString(string: "+", attributes: [.foregroundColor: added])
            case .removed: NSAttributedString(string: "-", attributes: [.foregroundColor: removed])
            case .hunk, .context: NSAttributedString(string: " ")
            }
        }
        return lines(markers, font: font, color: NSColor(style.secondary))
    }

    private func content(font: NSFont) -> NSAttributedString {
        var colors: [SyntaxToken.Kind: NSColor] = [:]
        let secondary = NSColor(style.secondary)
        let rows = document.rows.map { row -> NSAttributedString in
            guard row.kind != .hunk else { return NSAttributedString(string: row.text, attributes: [.foregroundColor: secondary]) }
            let line = NSMutableAttributedString(string: row.text)
            let utf8 = Array(row.text.utf8)
            for token in row.tokens where token.range.upperBound <= utf8.count {
                let location = String(decoding: utf8[..<token.range.lowerBound], as: UTF8.self).utf16.count
                let length = String(decoding: utf8[token.range], as: UTF8.self).utf16.count
                let color = colors[token.kind] ?? NSColor(style.color(for: token.kind))
                colors[token.kind] = color
                line.addAttribute(.foregroundColor, value: color, range: NSRange(location: location, length: length))
            }
            return line
        }
        return lines(rows, font: font, color: NSColor(style.text))
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
