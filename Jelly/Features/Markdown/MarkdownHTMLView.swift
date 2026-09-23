import SwiftUI

struct MarkdownHTMLView: View {
    let html: String
    let style: MarkdownStyle

    var body: some View {
        let images = html.matches(of: /<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["'][^>]*>/.ignoresCase()).map { String($0.1) }
        let text = html
            .replacing(/<[^>]+>/, with: "")
            .replacing("&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading, spacing: 8) {
            if !images.isEmpty {
                HStack(spacing: 8) {
                    ForEach(images, id: \.self) { source in
                        MarkdownImage(alt: "", source: source, style: style)
                    }
                }
            }
            if !text.isEmpty {
                Text(style.inline(text))
                    .font(style.bodyFont)
                    .foregroundStyle(style.text)
                    .textSelection(.enabled)
            }
        }
    }
}
