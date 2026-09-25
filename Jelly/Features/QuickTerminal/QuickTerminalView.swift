import JellyCore
import SwiftUI

struct QuickTerminalView: View {
    let model: QuickTerminalModel

    var body: some View {
        let theme = model.theme
        VStack(spacing: 0) {
            header(theme)
            if let surface = model.surface {
                QuickTerminalOutput(surface: surface)
                    .id(ObjectIdentifier(surface))
                    .frame(width: model.outputWidth, height: model.outputHeight)
                    .padding(.horizontal, Metrics.quickTerminalPadding)
                    .padding(.bottom, Metrics.quickTerminalOutputPadding * 2)
            }
        }
        .frame(width: Metrics.quickTerminalWidth)
        .background {
            let shape = RoundedRectangle(cornerRadius: Metrics.paletteCornerRadius, style: .continuous)
            shape
                .fill(Color(theme.background))
                .overlay(shape.strokeBorder(foreground.opacity(0.12), lineWidth: 1))
        }
        .clipShape(.rect(cornerRadius: Metrics.paletteCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            model.onContentHeightChange?(height)
        }
        .padding(Metrics.quickTerminalShadowMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var foreground: Color {
        Color(model.theme.foreground)
    }

    private func header(_ theme: Theme) -> some View {
        HStack(spacing: 14) {
            DirectoryBadge(path: model.displayDirectory, foreground: foreground, accent: Color(theme.accent))
                .help(model.directory)
            Spacer(minLength: 0)
            ForEach(Self.hints, id: \.key) { hint in
                HStack(spacing: 4) {
                    Text(hint.key).foregroundStyle(foreground.opacity(0.7))
                    Text(hint.label).foregroundStyle(foreground.opacity(0.4))
                }
            }
        }
        .font(.system(size: Metrics.statusFontSize))
        .lineLimit(1)
        .padding(.horizontal, Metrics.quickTerminalPadding - 4)
        .frame(height: Metrics.quickTerminalHeaderHeight)
    }

    private static let hints: [(key: String, label: String)] = [
        ("⌘↩", "Open in Jelly"),
        ("esc", "Hide"),
    ]
}
