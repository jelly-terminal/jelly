import AppKit
import JellyCore
import SwiftUI

struct MarkdownCodeBlock: View {
    let language: String?
    let text: String
    let style: MarkdownStyle

    @State private var isHovered = false
    @State private var copied = false

    var body: some View {
        ScrollView(.horizontal) {
            Text(highlighted)
                .font(style.code(size: Metrics.markdownCodeSize))
                .foregroundStyle(style.text)
                .lineSpacing(3)
                .textSelection(.enabled)
                .fixedSize()
                .padding(Metrics.markdownCodePadding)
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.fill, in: .rect(cornerRadius: Metrics.markdownCornerRadius))
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                if let language, !isHovered {
                    Text(language)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(style.secondary)
                }
                if isHovered {
                    Button(action: copy) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(style.secondary)
                    .help("Copy")
                }
            }
            .padding(6)
        }
        .onHover { isHovered = $0 }
    }

    private var highlighted: AttributedString {
        guard let language = language.flatMap(SyntaxLanguage.named) else { return AttributedString(text) }
        return style.highlighted(text, tokens: SyntaxHighlighter.tokens(in: text, language: language))
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}
