import JellyCore
import JellyTerminal
import SwiftUI

struct PaneArea: View {
    let model: WindowModel
    let theme: Theme
    let settings: JellyCore.Settings
    let isCovered: Bool

    private static let space = "panes"

    var body: some View {
        let workspace = model.workspace
        let tab = isCovered ? nil : workspace.selectedTab
        GeometryReader { proxy in
            let layout = tab.map { PaneLayout(tree: $0.layout, zoomed: $0.zoomedPaneID, size: proxy.size) }
            let visible = tab?.orderedPanes.filter { layout?.cards[$0.id] != nil } ?? []

            ZStack(alignment: .topLeading) {
                if let layout {
                    ForEach(visible) { pane in
                        card(layout.cards[pane.id]!) {
                            RoundedRectangle(cornerRadius: Metrics.paneCornerRadius, style: .continuous)
                                .fill(Color(theme.background, opacity: settings.window.backgroundOpacity))
                        }
                    }
                }

                TerminalHost(
                    surfaces: model.sessions.flatMap { $0.workspace.tabs.flatMap { $0.orderedPanes.map(\.surface) } },
                    cards: layout?.cards ?? [:],
                    padding: CGSize(width: settings.window.paddingX, height: settings.window.paddingY),
                    focused: tab?.surface,
                    onFocus: { model.workspace.selectedTab?.focus($0) }
                )
                .frame(width: proxy.size.width, height: proxy.size.height)

                if let tab, let layout {
                    ForEach(visible) { pane in
                        chrome(for: pane, in: tab, frame: layout.cards[pane.id]!)
                    }
                    ForEach(layout.dividers) { divider in
                        handle(for: divider, in: tab)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .coordinateSpace(.named(Self.space))
        }
        .transaction { $0.animation = nil }
    }

    private func card(_ frame: CGRect, @ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
    }

    private func chrome(for pane: PaneModel, in tab: TabModel, frame: CGRect) -> some View {
        let isFocused = pane.id == tab.focusedPaneID
        let isSplit = tab.panes.count > 1
        let workspace = model.workspace
        let needsAttention = pane.agentTone == .attention
        return ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Metrics.paneCornerRadius, style: .continuous)
                .strokeBorder(
                    needsAttention ? AgentTone.attention.color(theme).opacity(0.8)
                        : isFocused && isSplit ? Color(theme.accent).opacity(0.45) : Color(theme.foreground).opacity(0.1),
                    lineWidth: needsAttention ? Metrics.agentAttentionBorder : 1
                )
                .allowsHitTesting(false)
            PaneHeader(
                pane: pane,
                isFocused: isFocused,
                isZoomed: tab.zoomedPaneID != nil,
                isSplit: isSplit,
                theme: theme,
                onFocus: { tab.focus(pane.id) },
                onSplitRight: { workspace.split(.horizontal, pane: pane.id) },
                onSplitDown: { workspace.split(.vertical, pane: pane.id) },
                onZoom: {
                    tab.focus(pane.id)
                    tab.toggleZoom()
                },
                onClose: {
                    withAnimation(TabBar.animation) { workspace.requestClose(pane, in: tab, window: model.window) }
                }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: frame.width, height: frame.height)
        .offset(x: frame.minX, y: frame.minY)
    }

    private func handle(for divider: PaneLayout.Divider, in tab: TabModel) -> some View {
        Color.clear
            .contentShape(.rect)
            .frame(width: divider.frame.width, height: divider.frame.height)
            .pointerStyle(divider.axis == .horizontal ? .columnResize : .rowResize)
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .named(Self.space))
                    .onChanged { tab.setRatio(divider.ratio(at: $0.location), forSplit: divider.id) }
            )
            .onTapGesture(count: 2) { tab.equalize() }
            .offset(x: divider.frame.minX, y: divider.frame.minY)
    }
}
