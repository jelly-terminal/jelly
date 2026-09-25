import JellyCore
import SwiftUI

struct ActivityOverlay: View {
    let activity: ActivityModel
    let window: WindowModel
    let theme: Theme

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            let container = proxy.size
            let card = CGSize(width: min(Metrics.activityWidth, container.width), height: min(Metrics.activityHeight, container.height))
            ActivityWidget(
                activity: activity,
                window: window,
                theme: theme,
                onDrag: { dragOffset = $0 },
                onDrop: { settle(predicted: $0, card: card, container: container) },
                onClose: window.toggleActivity
            )
            .frame(width: card.width, height: card.height)
            .offset(dragOffset)
            .frame(width: container.width, height: container.height, alignment: activity.corner.alignment)
        }
        .padding(Metrics.activityInset)
    }

    private func settle(predicted translation: CGSize, card: CGSize, container: CGSize) {
        let center = activity.corner.center(of: card, in: container)
        let landing = CGPoint(x: center.x + translation.width, y: center.y + translation.height)
        withAnimation(.spring(duration: 0.35, bounce: 0.18)) {
            activity.corner = .nearest(to: landing, in: container)
            dragOffset = .zero
        }
    }
}
