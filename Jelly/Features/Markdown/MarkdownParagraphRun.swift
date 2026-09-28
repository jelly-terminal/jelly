import SwiftUI

struct MarkdownParagraphRun: View {
    let paragraphs: [String]
    let style: MarkdownStyle

    var body: some View {
        Text(joined)
            .font(style.bodyFont)
            .foregroundStyle(style.text)
            .lineSpacing(Metrics.markdownLineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }

    private var joined: AttributedString {
        var result = AttributedString()
        for (index, text) in paragraphs.enumerated() {
            if index > 0 { result += AttributedString("\n\n") }
            result += style.inline(text)
        }
        return result
    }
}
