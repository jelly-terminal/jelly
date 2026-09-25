import JellyCore
import SwiftUI

struct SystemView: View {
    let activity: ActivityModel
    let theme: Theme

    var body: some View {
        if let system = activity.snapshot?.system {
            let history = activity.history
            VStack(spacing: Metrics.activityCardSpacing) {
                MetricCard(title: "CPU", detail: load(system), foreground: foreground) {
                    Text(ActivityFormat.fraction(system.cpu)).foregroundStyle(foreground)
                } graph: {
                    Sparkline(values: history.cpu, maximum: 1, color: cpuColor)
                }
                MetricCard(
                    title: "Memory",
                    detail: "\(ActivityFormat.bytes(system.memoryUsed)) of \(ActivityFormat.bytes(system.memoryTotal))",
                    foreground: foreground
                ) {
                    Text(ActivityFormat.fraction(system.memoryFraction)).foregroundStyle(foreground)
                } graph: {
                    Sparkline(values: history.memory, maximum: 1, color: memoryColor)
                }
                MetricCard(title: "Network", detail: "↑ " + ActivityFormat.rate(system.sent), foreground: foreground, detailColor: sentColor) {
                    Text("↓ " + ActivityFormat.rate(system.received)).foregroundStyle(receivedColor)
                } graph: {
                    let peak = max(Self.networkFloor, (history.received + history.sent).max() ?? 0)
                    ZStack {
                        Sparkline(values: history.received, maximum: peak, color: receivedColor)
                        Sparkline(values: history.sent, maximum: peak, color: sentColor)
                    }
                }
            }
            .padding(Metrics.activityPadding + 2)
        } else {
            ActivityPlaceholder(symbol: nil, message: "Measuring…", foreground: foreground)
        }
    }

    private static let networkFloor = 64.0 * 1024

    private var foreground: Color { Color(theme.foreground) }
    private var cpuColor: Color { Color(theme.accent) }
    private var memoryColor: Color { Color(theme.palette[5]) }
    private var receivedColor: Color { Color(theme.palette[2]) }
    private var sentColor: Color { Color(theme.palette[6]) }

    private func load(_ system: SystemActivity) -> String {
        guard !system.load.isEmpty else { return "" }
        return "Load " + system.load.map { String(format: "%.2f", $0) }.joined(separator: " ")
    }
}
