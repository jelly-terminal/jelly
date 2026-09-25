import JellyCore
import SwiftUI

struct PaneHeader: View {
    let pane: PaneModel
    let isFocused: Bool
    let isZoomed: Bool
    let isSplit: Bool
    let theme: Theme
    let onFocus: () -> Void
    let onSplitRight: () -> Void
    let onSplitDown: () -> Void
    let onZoom: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "apple.terminal")
                .font(.system(size: Metrics.paneHeaderIconSize))
                .foregroundStyle(isFocused ? Color(theme.accent) : Color(theme.foreground).opacity(0.4))
            Text(pane.displayTitle)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color(theme.foreground).opacity(isFocused ? 0.85 : 0.5))
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                IconButton(symbol: "rectangle.split.2x1", help: "Split Right", theme: theme, action: onSplitRight)
                IconButton(symbol: "rectangle.split.1x2", help: "Split Down", theme: theme, action: onSplitDown)
                if isSplit {
                    IconButton(
                        symbol: isZoomed ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                        help: isZoomed ? "Restore Pane" : "Zoom Pane",
                        theme: theme,
                        action: onZoom
                    )
                }
                IconButton(symbol: "xmark", help: "Close Pane", theme: theme, action: onClose)
            }
            .opacity(showsControls ? 1 : 0)
            .allowsHitTesting(showsControls)
        }
        .font(.system(size: Metrics.paneHeaderFontSize, weight: .medium))
        .padding(.horizontal, Metrics.paneHeaderPadding)
        .frame(height: Metrics.paneHeaderHeight)
        .contentShape(.rect)
        .onTapGesture(perform: onFocus)
        .onHover { hovering in withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering } }
    }

    private var showsControls: Bool {
        isHovered || (isFocused && isSplit)
    }
}
