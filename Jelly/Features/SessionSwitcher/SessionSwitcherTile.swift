import JellyCore
import SwiftUI

struct SessionSwitcherTile: View {
    let session: SessionModel
    let isSelected: Bool
    let theme: Theme

    var body: some View {
        let color = session.color.color(theme)
        Text(initial)
            .font(.system(size: Metrics.switcherInitialFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .frame(width: Metrics.switcherTileSize, height: Metrics.switcherTileSize)
            .background(color.opacity(0.18), in: .rect(cornerRadius: Metrics.switcherTileCornerRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if let tone = session.workspace.agentTone, tone != .ready {
                    AgentIndicator(tone: tone, theme: theme)
                        .padding(Metrics.switcherBadgeInset)
                }
            }
            .padding(Metrics.switcherSelectionPadding)
            .background(
                Color(theme.foreground).opacity(isSelected ? 0.12 : 0),
                in: .rect(cornerRadius: Metrics.switcherSelectionCornerRadius, style: .continuous)
            )
            .contentShape(.rect)
    }

    private var initial: String {
        session.name.first.map { String($0).uppercased() } ?? "·"
    }
}
