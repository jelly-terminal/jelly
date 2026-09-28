import AppKit
import JellyCore
import SwiftUI

struct TextFileView: View {
    let lines: [String]
    let tokens: [[SyntaxToken]]?
    let truncated: Bool
    let style: MarkdownStyle

    @State private var viewportSize: CGSize = .zero

    var body: some View {
        let digits = max(String(lines.count).count, 2)
        ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    Text(gutter)
                        .foregroundStyle(style.secondary.opacity(0.7))
                        .frame(width: CGFloat(digits) * Metrics.markdownCodeSize * 0.62, alignment: .trailing)
                    Text(content)
                        .foregroundStyle(style.text)
                        .fixedSize()
                        .textSelection(.enabled)
                }
                .font(style.code(size: Metrics.markdownCodeSize))
                if truncated {
                    Text("Showing the first \(ViewerLoader.textLimit / 1_000_000) MB")
                        .font(.system(size: Metrics.chromeFontSize))
                        .foregroundStyle(style.secondary)
                        .padding(.top, 12)
                }
            }
            .padding(Metrics.viewerPadding)
            .frame(minWidth: viewportSize.width, minHeight: viewportSize.height, alignment: .topLeading)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewportSize = $0 }
    }

    private var lineParagraphStyle: NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        let height = Metrics.markdownCodeSize * 1.55
        paragraph.minimumLineHeight = height
        paragraph.maximumLineHeight = height
        return paragraph
    }

    private var gutter: AttributedString {
        var result = AttributedString(lines.indices.map { String($0 + 1) }.joined(separator: "\n"))
        result.paragraphStyle = lineParagraphStyle
        return result
    }

    private var content: AttributedString {
        var result = AttributedString()
        for index in lines.indices {
            result += attributed(lines[index], at: index)
            if index < lines.count - 1 { result += AttributedString("\n") }
        }
        result.paragraphStyle = lineParagraphStyle
        return result
    }

    private func attributed(_ line: String, at index: Int) -> AttributedString {
        guard !line.isEmpty else { return AttributedString() }
        guard let tokens, tokens.indices.contains(index) else { return AttributedString(line) }
        return style.highlighted(line, tokens: tokens[index])
    }
}
