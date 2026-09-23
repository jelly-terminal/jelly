import JellyCore
import SwiftUI
import UniformTypeIdentifiers

struct TabBar: View {
    let workspace: WorkspaceModel
    let theme: Theme
    let leadingInset: CGFloat
    let onClose: (TabModel) -> Void
    let onFind: () -> Void

    @Namespace private var selection
    @State private var draggedTab: TabModel?

    var body: some View {
        HStack(spacing: Metrics.tabSpacing) {
            HStack(spacing: Metrics.tabSpacing) {
                ForEach(workspace.tabs) { tab in
                        TabItem(
                            tab: tab,
                            isSelected: tab.id == workspace.selectedID,
                            theme: theme,
                            selection: selection,
                            onSelect: { withAnimation(Self.animation) { workspace.selectedID = tab.id } },
                            onClose: { withAnimation(Self.animation) { onClose(tab) } }
                        )
                        .onDrag {
                            draggedTab = tab
                            return NSItemProvider(object: tab.id.uuidString as NSString)
                        }
                        .onDrop(of: [.plainText], delegate: TabDropDelegate(target: tab, workspace: workspace, dragged: $draggedTab))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .leading)),
                            removal: .opacity.combined(with: .scale(scale: 0.85))
                        ))
                }
            }
            .animation(Self.animation, value: workspace.tabs.map(\.id))
            .animation(Self.animation, value: workspace.selectedID)

            Button {
                withAnimation(Self.animation) { _ = workspace.newTab() }
            } label: {
                Image(systemName: "plus")
                    .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                    .contentShape(.rect)
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
        .padding(.leading, leadingInset)
        .padding(.trailing, Metrics.chromePadding)
        .frame(height: Metrics.tabBarHeight)
    }

    static let animation = Animation.smooth(duration: 0.22)
}

private struct TabDropDelegate: DropDelegate {
    let target: TabModel
    let workspace: WorkspaceModel
    @Binding var dragged: TabModel?

    func dropEntered(info: DropInfo) {
        guard let dragged, dragged !== target else { return }
        withAnimation(TabBar.animation) { workspace.move(dragged, before: target) }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragged = nil
        return true
    }
}

private struct TabItem: View {
    let tab: TabModel
    let isSelected: Bool
    let theme: Theme
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
            Image(systemName: "terminal")
                .foregroundStyle(isSelected ? Color(theme.accent) : Color(theme.foreground).opacity(0.5))
            Text(tab.displayTitle)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color(theme.foreground).opacity(isSelected ? 1 : 0.6))
        }
        .padding(.leading, Metrics.tabHorizontalPadding / 2)
        .padding(.trailing, Metrics.tabHorizontalPadding)
        .frame(height: Metrics.tabHeight)
        .frame(maxWidth: Metrics.tabMaxWidth, alignment: .leading)
        .background {
            ZStack {
                if isHovered, !isSelected {
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
        .contentShape(.capsule)
        .onTapGesture(perform: onSelect)
        .onHover { hovering in withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering } }
    }
}
