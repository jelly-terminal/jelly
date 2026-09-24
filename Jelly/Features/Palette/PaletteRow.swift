import JellyCore
import SwiftUI

struct PaletteRow: View {
    let match: PaletteMatch
    let isSelected: Bool
    let foreground: Color
    let accent: Color

    var body: some View {
        let item = match.item
        HStack(spacing: 8) {
            Image(systemName: item.symbol ?? "circle")
                .font(.system(size: Metrics.chromeFontSize))
                .foregroundStyle(foreground.opacity(0.55))
                .frame(width: Metrics.paletteIconWidth)
            Text(highlightedTitle)
                .font(.system(size: Metrics.chromeFontSize + 0.5))
                .foregroundStyle(foreground)
                .lineLimit(1)
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.system(size: Metrics.statusFontSize))
                    .foregroundStyle(foreground.opacity(0.4))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if item.isCurrent {
                Image(systemName: "checkmark")
                    .font(.system(size: Metrics.statusFontSize, weight: .semibold))
                    .foregroundStyle(accent)
            }
            if let shortcut = item.shortcut {
                Text(shortcut.symbols)
                    .font(.system(size: Metrics.statusFontSize))
                    .foregroundStyle(foreground.opacity(0.55))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: Metrics.paletteRowHeight)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: Metrics.paletteRowCornerRadius, style: .continuous)
                    .fill(accent.opacity(0.22))
            }
        }
        .contentShape(.rect)
    }

    private var highlightedTitle: AttributedString {
        var text = AttributedString()
        let positions = Set(match.positions)
        for (offset, character) in match.item.title.enumerated() {
            var piece = AttributedString(String(character))
            if positions.contains(offset) {
                piece.foregroundColor = accent
                piece.inlinePresentationIntent = .stronglyEmphasized
            }
            text += piece
        }
        return text
    }
}
