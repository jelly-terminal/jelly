import JellyCore
import SwiftUI

struct ChangeRowView: View {
    let change: GitChange
    let isSelected: Bool
    let isFocused: Bool
    let theme: Theme
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        let foreground = Color(theme.foreground)
        HStack(spacing: 6) {
            Text(change.letter)
                .font(.system(size: Metrics.statusFontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(change.color(in: theme))
                .frame(width: Metrics.changesBadgeWidth)
            Text(change.name)
                .font(.system(size: Metrics.chromeFontSize))
                .foregroundStyle(foreground.opacity(0.85))
                .strikethrough(change.kind == .deleted, color: foreground.opacity(0.5))
                .lineLimit(1)
                .layoutPriority(1)
            Text(detail)
                .font(.system(size: Metrics.statusFontSize))
                .foregroundStyle(foreground.opacity(0.4))
                .lineLimit(1)
                .truncationMode(.head)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .frame(height: Metrics.explorerRowHeight)
        .background {
            RoundedRectangle(cornerRadius: Metrics.sidebarRowCornerRadius / 1.5, style: .continuous)
                .fill(background)
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .help(change.originalPath.map { "\($0) → \(change.path)" } ?? change.path)
    }

    private var detail: String {
        if let original = change.originalPath { return "← " + (original as NSString).lastPathComponent }
        return change.folder
    }

    private var background: Color {
        if isSelected { return Color(theme.accent).opacity(isFocused ? 0.3 : 0.15) }
        return isHovered ? Color(theme.foreground).opacity(0.06) : .clear
    }
}
