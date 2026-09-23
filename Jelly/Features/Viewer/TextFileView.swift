import JellyCore
import SwiftUI

struct TextFileView: View {
    let lines: [String]
    let tokens: [[SyntaxToken]]?
    let truncated: Bool
    let style: MarkdownStyle

    @State private var viewportWidth: CGFloat = 0

    var body: some View {
        let digits = max(String(lines.count).count, 2)
        ScrollView([.vertical, .horizontal]) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .firstTextBaseline, spacing: 16) {
                        Text(String(index + 1))
                            .foregroundStyle(style.secondary.opacity(0.7))
                            .frame(width: CGFloat(digits) * Metrics.markdownCodeSize * 0.62, alignment: .trailing)
                        Text(attributed(line, at: index))
                            .foregroundStyle(style.text)
                            .fixedSize()
                    }
                    .font(style.code(size: Metrics.markdownCodeSize))
                    .frame(height: Metrics.markdownCodeSize * 1.55)
                }
                if truncated {
                    Text("Showing the first \(ViewerLoader.textLimit / 1_000_000) MB")
                        .font(.system(size: Metrics.chromeFontSize))
                        .foregroundStyle(style.secondary)
                        .padding(.top, 12)
                }
            }
            .textSelection(.enabled)
            .padding(Metrics.viewerPadding)
            .frame(minWidth: viewportWidth, alignment: .leading)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
    }

    private func attributed(_ line: String, at index: Int) -> AttributedString {
        guard !line.isEmpty else { return AttributedString(" ") }
        guard let tokens, tokens.indices.contains(index) else { return AttributedString(line) }
        return style.highlighted(line, tokens: tokens[index])
    }
}
