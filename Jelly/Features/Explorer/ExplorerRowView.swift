import JellyCore
import SwiftUI

struct ExplorerRowView: View {
    let row: ExplorerRow
    let isSelected: Bool
    let isFocused: Bool
    let status: GitChange.Kind?
    let theme: Theme
    let onToggle: () -> Void
    let onSelect: () -> Void
    let onOpen: () -> Void

    @State private var isHovered = false

    var body: some View {
        let foreground = Color(theme.foreground)
        HStack(spacing: 5) {
            Image(systemName: "chevron.right")
                .font(.system(size: 8.5, weight: .bold))
                .rotationEffect(.degrees(row.isExpanded ? 90 : 0))
                .foregroundStyle(foreground.opacity(0.45))
                .frame(width: Metrics.explorerChevronWidth + 8, height: Metrics.explorerRowHeight)
                .contentShape(.rect)
                .onTapGesture(perform: onToggle)
                .padding(.horizontal, -4)
                .opacity(row.entry.isDirectory ? 1 : 0)
                .allowsHitTesting(row.entry.isDirectory)
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: Metrics.explorerIconSize))
                    .foregroundStyle(row.entry.isDirectory ? Color(theme.accent) : foreground.opacity(0.55))
                    .frame(width: Metrics.explorerIconSize + 4)
                Text(row.entry.name)
                    .font(.system(size: Metrics.chromeFontSize))
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if let status {
                    statusBadge(status)
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .onTapGesture(count: 2, perform: onOpen)
            .simultaneousGesture(TapGesture().onEnded(onSelect))
        }
        .padding(.leading, CGFloat(row.depth) * Metrics.explorerIndent + 4)
        .padding(.trailing, 6)
        .frame(height: Metrics.explorerRowHeight)
        .background {
            RoundedRectangle(cornerRadius: Metrics.sidebarRowCornerRadius / 1.5, style: .continuous)
                .fill(background)
        }
        .contentShape(.rect)
        .onHover { isHovered = $0 }
        .help(row.entry.name)
    }

    private var nameColor: Color {
        let opacity = row.entry.name.hasPrefix(".") ? 0.5 : 0.85
        guard let status else { return Color(theme.foreground).opacity(opacity) }
        return status.color(in: theme).opacity(opacity + 0.15)
    }

    @ViewBuilder
    private func statusBadge(_ status: GitChange.Kind) -> some View {
        if row.entry.isDirectory {
            Circle()
                .fill(status.color(in: theme).opacity(0.8))
                .frame(width: Metrics.explorerStatusDotSize, height: Metrics.explorerStatusDotSize)
                .frame(width: Metrics.changesBadgeWidth)
        } else {
            Text(status.letter)
                .font(.system(size: Metrics.statusFontSize, weight: .bold, design: .monospaced))
                .foregroundStyle(status.color(in: theme))
                .frame(width: Metrics.changesBadgeWidth)
        }
    }

    private var background: Color {
        if isSelected { return Color(theme.accent).opacity(isFocused ? 0.3 : 0.15) }
        return isHovered ? Color(theme.foreground).opacity(0.06) : .clear
    }

    private var symbol: String {
        if row.entry.isDirectory { return row.isExpanded ? "folder.fill" : "folder" }
        if row.entry.isMarkdown { return "doc.richtext" }
        switch row.entry.url.pathExtension.lowercased() {
        case "swift": return "swift"
        case "png", "jpg", "jpeg", "gif", "heic", "webp", "svg", "icns": return "photo"
        case "json", "toml", "yaml", "yml", "plist", "xml": return "curlybraces"
        case "sh", "fish", "zsh", "bash": return "terminal"
        case "zip", "gz", "tar", "xz", "dmg": return "archivebox"
        case "pdf": return "doc.text.image"
        case "txt", "log": return "doc.plaintext"
        default: return "doc.text"
        }
    }
}
