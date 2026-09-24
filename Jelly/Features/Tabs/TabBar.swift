import JellyCore
import SwiftUI

struct TabBar: View {
    let workspace: WorkspaceModel
    let theme: Theme
    let style: WindowSettings.TabStyle
    let leadingInset: CGFloat
    let updateVersion: String?
    let onUpdate: () -> Void
    let onClose: (TabModel) -> Void
    let onFind: () -> Void

    @Namespace private var selection
    @State private var drag: TabDrag?
    @State private var tabFrames: [TabModel.ID: CGRect] = [:]

    var body: some View {
        HStack(spacing: Metrics.tabSpacing) {
            HStack(spacing: Metrics.tabSpacing) {
                ForEach(workspace.tabs) { tab in
                        TabItem(
                            tab: tab,
                            isSelected: tab.id == workspace.selectedID,
                            theme: theme,
                            style: style,
                            selection: selection,
                            onSelect: { withAnimation(Self.animation) { workspace.selectedID = tab.id } },
                            onClose: { withAnimation(Self.animation) { onClose(tab) } }
                        )
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { tabFrames[tab.id] = $0 }
                        .offset(x: dragOffset(for: tab))
                        .zIndex(drag?.tabID == tab.id ? 1 : 0)
                        .highPriorityGesture(reorderGesture(for: tab))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .leading)),
                            removal: .opacity.combined(with: .scale(scale: 0.85))
                        ))
                }
            }
            .animation(Self.animation, value: workspace.tabs.map(\.id))
            .animation(Self.animation, value: workspace.selectedID)
            .animation(Self.animation, value: updateVersion)

            Button {
                withAnimation(Self.animation) { _ = workspace.newTab() }
            } label: {
                Image(systemName: "plus")
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                    .background {
                        if style == .card {
                            RoundedRectangle(cornerRadius: Metrics.tabCardCornerRadius)
                                .fill(Color(theme.foreground).opacity(0.06))
                        }
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.foreground).opacity(0.7))
            .help("New Tab")

            Spacer(minLength: 0)

            if let updateVersion {
                Button(action: onUpdate) {
                    Text("Update available")
                        .padding(.horizontal, Metrics.tabSpacing)
                        .frame(height: Metrics.controlSize)
                }
                .buttonStyle(.glass)
                .tint(.accentColor)
                .help("Jelly \(updateVersion) is ready to install")
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Button(action: onFind) {
                Image(systemName: "magnifyingglass")
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(.clear)
            .help("Find")
        }
        .font(.system(size: Metrics.chromeFontSize, weight: .medium))
        .padding(.leading, leadingInset)
        .padding(.trailing, Metrics.chromePadding)
        .frame(height: Metrics.tabBarHeight)
        .coordinateSpace(.named(Self.space))
    }

    static let animation = Animation.smooth(duration: 0.22)
    private static let space = "TabBar"

    private func dragOffset(for tab: TabModel) -> CGFloat {
        guard let drag, let index = workspace.tabs.firstIndex(where: { $0 === tab }) else { return 0 }
        if tab.id == drag.tabID { return draggedMinX(in: drag) - slotMinX(at: drag.from, in: workspace.tabs.map(\.id), drag: drag) }
        let shift = (drag.widths[drag.tabID] ?? 0) + Metrics.tabSpacing
        if index > drag.from, index <= drag.index { return -shift }
        if index < drag.from, index >= drag.index { return shift }
        return 0
    }

    private func slotMinX(at index: Int, in order: [TabModel.ID], drag: TabDrag) -> CGFloat {
        order.prefix(index).reduce(drag.origin) { x, id in x + (drag.widths[id] ?? 0) + Metrics.tabSpacing }
    }

    private func displayOrder(for drag: TabDrag) -> [TabModel.ID] {
        var order = workspace.tabs.map(\.id).filter { $0 != drag.tabID }
        order.insert(drag.tabID, at: drag.index)
        return order
    }

    private func draggedMinX(in drag: TabDrag) -> CGFloat {
        let ids = workspace.tabs.map(\.id)
        let maxX = slotMinX(at: ids.count, in: ids, drag: drag) - Metrics.tabSpacing - (drag.widths[drag.tabID] ?? 0)
        return min(max(drag.location - drag.grabOffset, drag.origin), maxX)
    }

    private func reorderGesture(for tab: TabModel) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.space))
            .onChanged { value in
                if drag == nil {
                    guard let origin = workspace.tabs.first.flatMap({ tabFrames[$0.id]?.minX }),
                          let frame = tabFrames[tab.id],
                          let from = workspace.tabs.firstIndex(where: { $0 === tab })
                    else { return }
                    drag = TabDrag(
                        tabID: tab.id,
                        from: from,
                        index: from,
                        grabOffset: value.startLocation.x - frame.minX,
                        location: value.location.x,
                        origin: origin,
                        widths: tabFrames.mapValues(\.width)
                    )
                    workspace.selectedID = tab.id
                }
                drag?.location = value.location.x
                updateDropIndex()
            }
            .onEnded { _ in
                guard let drag else { return }
                withAnimation(Self.animation) {
                    if drag.index != drag.from { workspace.move(tab, before: workspace.tabs[drag.index]) }
                    self.drag = nil
                }
            }
    }

    private func updateDropIndex() {
        guard var drag, let width = drag.widths[drag.tabID] else { return }
        let minX = draggedMinX(in: drag)
        let maxX = minX + width
        while true {
            let order = displayOrder(for: drag)
            let midX = { (index: Int) in slotMinX(at: index, in: order, drag: drag) + (drag.widths[order[index]] ?? 0) / 2 }
            if drag.index + 1 < order.count, maxX > midX(drag.index + 1) {
                drag.index += 1
            } else if drag.index > 0, minX < midX(drag.index - 1) {
                drag.index -= 1
            } else {
                break
            }
        }
        if drag.index != self.drag?.index {
            withAnimation(Self.animation) { self.drag = drag }
        } else {
            self.drag = drag
        }
    }
}

private struct TabDrag {
    let tabID: TabModel.ID
    let from: Int
    var index: Int
    let grabOffset: CGFloat
    var location: CGFloat
    let origin: CGFloat
    let widths: [TabModel.ID: CGFloat]
}

private struct TabItem: View {
    let tab: TabModel
    let isSelected: Bool
    let theme: Theme
    let style: WindowSettings.TabStyle
    let selection: Namespace.ID
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 16, height: 16)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.foreground).opacity(0.7))
            .opacity(isHovered ? 1 : 0)
            .allowsHitTesting(isHovered)
            .help("Close Tab")
            if let tone = tab.agentTone, tone != .ready {
                AgentIndicator(tone: tone, theme: theme)
            } else {
                Image(systemName: "terminal")
                    .foregroundStyle(isSelected ? Color(theme.accent) : Color(theme.foreground).opacity(0.5))
            }
            Text(tab.displayTitle)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color(theme.foreground).opacity(isSelected ? 1 : 0.6))
        }
        .padding(.leading, Metrics.tabHorizontalPadding / 2)
        .padding(.trailing, Metrics.tabHorizontalPadding)
        .frame(height: Metrics.tabHeight)
        .frame(minWidth: style == .card ? Metrics.tabCardMinWidth : nil, maxWidth: Metrics.tabMaxWidth, alignment: .leading)
        .background {
            switch style {
            case .glass: glassBackground
            case .card: cardBackground
            }
        }
        .contentShape(shape)
        .onTapGesture(perform: onSelect)
        .onHover { hovering in withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering } }
    }

    private var shape: AnyShape {
        switch style {
        case .glass: AnyShape(.capsule)
        case .card: AnyShape(.rect(cornerRadius: Metrics.tabCardCornerRadius))
        }
    }

    private var glassBackground: some View {
        ZStack {
            if !isSelected, tab.agentTone == .attention {
                Capsule().fill(AgentTone.attention.color(theme).opacity(0.14))
            } else if isHovered, !isSelected {
                Capsule().fill(Color(theme.foreground).opacity(0.06))
            }
            if isSelected {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
                    .matchedGeometryEffect(id: "selection", in: selection)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Metrics.tabCardCornerRadius)
            .fill(cardFill)
            .strokeBorder(Color(theme.foreground).opacity(isSelected ? 0.12 : 0), lineWidth: 1)
    }

    private var cardFill: Color {
        if !isSelected, tab.agentTone == .attention { return AgentTone.attention.color(theme).opacity(0.14) }
        return Color(theme.foreground).opacity(isSelected ? 0.12 : isHovered ? 0.08 : 0.04)
    }
}
