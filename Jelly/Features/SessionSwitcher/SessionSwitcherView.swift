import JellyCore
import SwiftUI

struct SessionSwitcherView: View {
    let switcher: SessionSwitcherModel
    let theme: Theme
    let onPick: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: onCancel)

            VStack(spacing: Metrics.switcherSpacing) {
                ViewThatFits(in: .horizontal) {
                    tiles
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) { tiles }
                            .onAppear { proxy.scrollTo(switcher.selectedIndex, anchor: .center) }
                            .onChange(of: switcher.selectedIndex) { _, index in proxy.scrollTo(index, anchor: .center) }
                    }
                }
                caption
            }
            .padding(Metrics.switcherPadding)
            .background {
                let shape = RoundedRectangle(cornerRadius: Metrics.switcherCornerRadius, style: .continuous)
                shape
                    .fill(Color(theme.background))
                    .overlay(shape.strokeBorder(foreground.opacity(0.12), lineWidth: 1))
            }
            .clipShape(.rect(cornerRadius: Metrics.switcherCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
            .padding(Metrics.switcherInset)
        }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }

    private var tiles: some View {
        HStack(spacing: Metrics.switcherTileSpacing) {
            ForEach(Array(switcher.sessions.enumerated()), id: \.element.id) { index, session in
                SessionSwitcherTile(session: session, isSelected: index == switcher.selectedIndex, theme: theme)
                    .id(index)
                    .onTapGesture { onPick(index) }
            }
        }
    }

    private var caption: some View {
        let session = switcher.selected
        return VStack(spacing: 2) {
            Text(session.name)
                .font(.system(size: Metrics.switcherNameFontSize, weight: .semibold))
                .foregroundStyle(foreground)
            Text(session.tabCount == 1 ? "1 tab" : "\(session.tabCount) tabs")
                .font(.system(size: Metrics.statusFontSize))
                .foregroundStyle(foreground.opacity(0.5))
        }
        .lineLimit(1)
        .frame(maxWidth: Metrics.switcherCaptionWidth)
    }
}
