import JellyCore
import SwiftUI

struct ViewerCard: View {
    @Bindable var viewer: ViewerModel
    let theme: Theme
    let onClose: () -> Void
    let onStepChange: (Int) -> Void

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
        .onKeyPress(phases: .down, action: handleDiffKey)
        .onAppear { isFocused = true }
    }

    private func header(style: MarkdownStyle) -> some View {
        HStack(spacing: 6) {
            if !viewer.history.isEmpty {
                headerButton("chevron.left", help: "Back", action: viewer.back)
            }
            Image(systemName: headerSymbol)
                .font(.system(size: Metrics.paneHeaderIconSize + 1))
                .foregroundStyle(style.secondary)
            Text(viewer.title)
                .font(.system(size: Metrics.chromeFontSize, weight: .medium))
                .foregroundStyle(style.text)
                .lineLimit(1)
                .help(viewer.url.path(percentEncoded: false))
            if let diff = viewer.diff {
                diffSummary(diff, style: style)
            }
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

    private var headerSymbol: String {
        if viewer.diff != nil { return "plus.forwardslash.minus" }
        return switch viewer.content {
        case .markdown: "doc.richtext"
        case .image: "photo"
        default: "doc.text"
        }
    }

    @ViewBuilder
    private func diffSummary(_ diff: DiffTarget, style: MarkdownStyle) -> some View {
        Text(diff.change.area.title)
            .font(.system(size: Metrics.statusFontSize, weight: .medium))
            .foregroundStyle(style.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(style.fill, in: .capsule)
        if case .diff(let document) = viewer.content {
            HStack(spacing: 4) {
                Text("+\(document.additions)").foregroundStyle(Color(theme.palette[2]))
                Text("−\(document.deletions)").foregroundStyle(Color(theme.palette[1]))
            }
            .font(.system(size: Metrics.statusFontSize, weight: .medium).monospacedDigit())
        }
    }

    private func handleDiffKey(_ press: KeyPress) -> KeyPress.Result {
        guard viewer.diff != nil else { return .ignored }
        let modifiers = press.modifiers.intersection([.command, .control, .option, .shift])
        switch (press.key, modifiers) {
        case (.downArrow, .option):
            onStepChange(1)
        case (.upArrow, .option):
            onStepChange(-1)
        case (_, []) where press.characters == "]":
            viewer.moveHunk(by: 1)
        case (_, []) where press.characters == "[":
            viewer.moveHunk(by: -1)
        default:
            return .ignored
        }
        return .handled
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
        case .image(let image):
            ImageFileView(image: image, style: style)
        case .diff(let document):
            DiffView(document: document, style: style, hunkMove: viewer.hunkMove)
                .id(viewer.url)
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
