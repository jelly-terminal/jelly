import JellyCore
import SwiftUI

struct AgentIndicator: View {
    let tone: AgentTone
    let theme: Theme
    var size: CGFloat = Metrics.agentIndicatorSize

    var body: some View {
        let color = tone.color(theme)
        ZStack {
            switch tone {
            case .working:
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                    ZStack {
                        Circle().stroke(color.opacity(0.2), lineWidth: size * 0.16)
                        Circle()
                            .trim(from: 0, to: 0.3)
                            .stroke(color, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round))
                            .rotationEffect(.degrees(turn * 360))
                    }
                }
            case .attention:
                Circle().fill(color.opacity(0.25))
                Circle().fill(color).padding(size * 0.22)
            case .finished:
                Circle().fill(color).padding(size * 0.22)
            case .ready:
                Circle().stroke(color, lineWidth: size * 0.14).padding(size * 0.22)
            }
        }
        .frame(width: size, height: size)
    }
}
