import JellyCore
import SwiftUI

struct StatusBar: View {
    let sessionName: String
    let sessionColor: SessionColor
    let tabCount: Int
    let paneCount: Int
    let gridSize: (cols: Int, rows: Int)?
    let agent: AgentHighlight?
    let theme: Theme
    let onAgent: () -> Void

    var body: some View {
        HStack {
            if let agent, agent.tone != .ready {
                StatusAgentButton(agent: agent, theme: theme, action: onAgent)
            }
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(sessionColor.color(theme))
                    .frame(width: 6, height: 6)
                Text(sessionName)
                separator
                Text(tabCount == 1 ? "1 tab" : "\(tabCount) tabs")
                if paneCount > 1 {
                    separator
                    Text("\(paneCount) panes")
                }
                if let gridSize, gridSize.cols > 0 {
                    separator
                    Text("\(gridSize.cols)×\(gridSize.rows)")
                        .monospacedDigit()
                }
            }
            .font(.system(size: Metrics.statusFontSize, weight: .medium))
            .foregroundStyle(Color(theme.foreground).opacity(0.5))
            .padding(.horizontal, Metrics.paneHeaderPadding)
        }
        .padding(.horizontal, Metrics.chromePadding)
        .frame(height: Metrics.statusBarHeight)
        .transaction { $0.animation = nil }
    }

    private var separator: some View {
        Text("·").opacity(0.5)
    }
}

private struct StatusAgentButton: View {
    let agent: AgentHighlight
    let theme: Theme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        let color = agent.tone.color(theme)
        Button(action: action) {
            HStack(spacing: 6) {
                AgentIndicator(tone: agent.tone, theme: theme, size: Metrics.agentChipIndicatorSize)
                Text(title)
                if agent.others > 0 {
                    Text("+\(agent.others)").opacity(0.6)
                }
            }
            .padding(.horizontal, Metrics.agentChipPadding)
            .frame(height: Metrics.agentChipHeight)
            .background(color.opacity(isHovered ? 0.22 : 0.12), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .foregroundStyle(agent.tone == .working ? Color(theme.foreground).opacity(0.6) : color)
        .onHover { isHovered = $0 }
        .help("Show \(agent.location.tab.displayTitle)")
    }

    private var title: String {
        guard let presence = agent.location.pane.agent else { return "" }
        switch agent.tone {
        case .attention: return "\(presence.name) · \(presence.label)"
        case .finished: return "\(presence.name) is done"
        case .working, .ready: return "\(presence.name) is working"
        }
    }
}
