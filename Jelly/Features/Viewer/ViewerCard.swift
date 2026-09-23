import JellyCore
import SwiftUI

struct ViewerCard: View {
    @Bindable var viewer: ViewerModel
    let theme: Theme
    let onClose: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        let style = MarkdownStyle(theme: theme, codeFont: viewer.codeFont, baseURL: viewer.url.deletingLastPathComponent())
        VStack(spacing: 0) {
            header(style: style)
            Rectangle().fill(style.faint).frame(height: 1)
            content(style: style)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            let shape = RoundedRectangle(cornerRadius: Metrics.paneCornerRadius, style: .continuous)
            shape
                .fill(Color(theme.background))
                .overlay(shape.strokeBorder(Color(theme.foreground).opacity(0.1), lineWidth: 1))
        }
        .clipShape(.rect(cornerRadius: Metrics.paneCornerRadius, style: .continuous))
        .environment(\.openURL, OpenURLAction { viewer.handle($0) })
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .onAppear { isFocused = true }
    }

    private func header(style: MarkdownStyle) -> some View {
        HStack(spacing: 6) {
            if !viewer.history.isEmpty {
                headerButton("chevron.left", help: "Back", action: viewer.back)
            }
            Image(systemName: isMarkdown ? "doc.richtext" : "doc.text")
                .font(.system(size: Metrics.paneHeaderIconSize + 1))
                .foregroundStyle(style.secondary)
            Text(viewer.title)
                .font(.system(size: Metrics.chromeFontSize, weight: .medium))
                .foregroundStyle(style.text)
                .lineLimit(1)
                .help(viewer.url.path(percentEncoded: false))
            Spacer()
            if !viewer.outline.isEmpty {
                Menu {
                    ForEach(viewer.outline) { heading in
                        Button(String(repeating: "    ", count: heading.level - 1) + heading.title) {
                            viewer.pendingAnchor = heading.anchor
                        }
                    }
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: Metrics.paneHeaderIconSize + 1))
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                .foregroundStyle(style.secondary)
                .help("Contents")
            }
            headerButton("xmark", help: "Close", action: onClose)
        }
        .padding(.horizontal, Metrics.paneHeaderPadding)
        .frame(height: Metrics.paneHeaderHeight + 4)
    }

    private var isMarkdown: Bool {
        if case .markdown = viewer.content { return true }
        return false
    }

    private func headerButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metrics.paneHeaderIconSize, weight: .semibold))
                .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.foreground).opacity(0.6))
        .help(help)
    }

    @ViewBuilder
    private func content(style: MarkdownStyle) -> some View {
        switch viewer.content {
        case .loading:
            ProgressView().controlSize(.small)
        case .markdown(let document):
            MarkdownView(document: document, style: style, anchor: $viewer.pendingAnchor)
        case .text(let lines, let tokens, let truncated):
            TextFileView(lines: lines, tokens: tokens, truncated: truncated, style: style)
        case .unavailable(let message):
            VStack(spacing: 8) {
                Image(systemName: "doc.questionmark")
                    .font(.system(size: 24))
                Text(message)
            }
            .foregroundStyle(style.secondary)
        }
    }
}
