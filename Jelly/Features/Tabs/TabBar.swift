import JellyCore
import SwiftUI

struct TabBar: View {
    let workspace: WorkspaceModel
    let theme: Theme
    let onClose: (TabModel) -> Void
    let onFind: () -> Void

    @Namespace private var glass

    var body: some View {
        HStack(spacing: Metrics.tabSpacing) {
            GlassEffectContainer(spacing: Metrics.tabSpacing) {
                HStack(spacing: Metrics.tabSpacing) {
                    ForEach(workspace.tabs) { tab in
                        TabItem(
                            tab: tab,
                            isSelected: tab.id == workspace.selectedID,
                            theme: theme,
                            namespace: glass,
                            onSelect: { workspace.selectedID = tab.id },
                            onClose: { onClose(tab) }
                        )
                    }
                }
            }
            .animation(.smooth(duration: 0.25), value: workspace.selectedID)
            .animation(.smooth(duration: 0.25), value: workspace.tabs.map(\.id))

            Button {
                workspace.newTab()
            } label: {
                Image(systemName: "plus")
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(theme.foreground).opacity(0.7))
            .help("New Tab")

            Spacer(minLength: 0)

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
        .padding(.leading, Metrics.trafficLightInset)
        .padding(.trailing, Metrics.chromePadding)
        .frame(height: Metrics.tabBarHeight)
    }
}

private struct TabItem: View {
    let tab: TabModel
    let isSelected: Bool
    let theme: Theme
    let namespace: Namespace.ID
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Image(systemName: "terminal")
                    .foregroundStyle(isSelected ? Color(theme.accent) : Color(theme.foreground).opacity(0.5))
                    .opacity(isHovered ? 0 : 1)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 16)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(theme.foreground).opacity(0.7))
                .opacity(isHovered ? 1 : 0)
                .help("Close Tab")
            }
            .frame(width: 16, height: 16)
            Text(tab.displayTitle)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color(theme.foreground).opacity(isSelected ? 1 : 0.6))
        }
        .padding(.horizontal, Metrics.tabHorizontalPadding)
        .frame(height: Metrics.tabHeight)
        .frame(maxWidth: Metrics.tabMaxWidth)
        .contentShape(.capsule)
        .glassEffect(isSelected ? .regular : .identity, in: .capsule)
        .glassEffectID(tab.id, in: namespace)
        .onTapGesture(perform: onSelect)
        .onHover { hovering in withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering } }
    }
}
