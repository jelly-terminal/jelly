import JellyCore
import SwiftUI

struct ActivityWidget: View {
    @Bindable var activity: ActivityModel
    let window: WindowModel
    let theme: Theme
    let onDrag: (CGSize) -> Void
    let onDrop: (CGSize) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(foreground.opacity(0.08)).frame(height: 1)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            let shape = RoundedRectangle(cornerRadius: Metrics.activityCornerRadius, style: .continuous)
            shape
                .fill(Color(theme.background))
                .overlay(shape.strokeBorder(foreground.opacity(0.12), lineWidth: 1))
        }
        .clipShape(.rect(cornerRadius: Metrics.activityCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
    }

    private var foreground: Color {
        Color(theme.foreground)
    }

    private var header: some View {
        HStack(spacing: 6) {
            ActivityTabPicker(selection: $activity.tab, theme: theme)
                .pointerStyle(.default)
            Spacer(minLength: 0)
            IconButton(symbol: "xmark", help: "Close Activity", theme: theme, action: onClose)
                .pointerStyle(.default)
        }
        .padding(.leading, Metrics.activityPadding + 2)
        .padding(.trailing, Metrics.activityPadding + 2)
        .frame(height: Metrics.activityHeaderHeight)
        .background {
            Color.clear
                .contentShape(.rect)
                .pointerStyle(.grabIdle)
                .gesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .global)
                        .onChanged { onDrag($0.translation) }
                        .onEnded { onDrop($0.predictedEndTranslation) }
                )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch activity.tab {
        case .processes: ProcessesView(activity: activity, window: window, theme: theme)
        case .ports: PortsView(activity: activity, window: window, theme: theme)
        case .system: SystemView(activity: activity, theme: theme)
        }
    }
}
