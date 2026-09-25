import JellyCore
import SwiftUI

struct PaneActivityRow: View {
    let pane: PaneActivity
    let location: PaneLocation?
    let isExpanded: Bool
    let activity: ActivityModel
    let theme: Theme
    let onReveal: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            disclosure
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: Metrics.chromeFontSize + 0.5, weight: .medium))
                        .foregroundStyle(foreground.opacity(pane.isIdle ? 0.5 : 0.95))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let tone = location?.pane.agentTone {
                        AgentIndicator(tone: tone, theme: theme, size: Metrics.agentChipIndicatorSize)
                    }
                }
                HStack(spacing: 5) {
                    if let location {
                        Circle()
                            .fill(location.session.color.color(theme))
                            .frame(width: Metrics.activitySessionDot, height: Metrics.activitySessionDot)
                    }
                    Text(subtitle)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(size: Metrics.statusFontSize))
                .foregroundStyle(foreground.opacity(0.45))
            }
            Spacer(minLength: 8)
            ActivityValues(cpu: pane.cpu, memory: pane.memory, foreground: foreground, warning: Color(theme.palette[3]))
        }
        .padding(.horizontal, Metrics.activityRowPadding)
        .frame(height: Metrics.activityPaneRowHeight)
        .activityRowBackground(foreground)
        .onTapGesture(perform: onReveal)
        .help(location.map { "Show \($0.tab.displayTitle) in \($0.session.name)" } ?? "")
        .contextMenu {
            ProcessMenu(
                pid: pane.foreground?.pid ?? pane.shell?.pid ?? 0,
                activity: activity,
                group: pane.foreground?.pid,
                onReveal: onReveal
            )
        }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }

    private var title: String {
        pane.foreground?.command ?? pane.shell?.command ?? location?.pane.displayTitle ?? "shell"
    }

    private var subtitle: String {
        var parts: [String] = []
        if let location { parts.append("\(location.session.name) › \(location.tab.displayTitle)") }
        if let running = pane.foreground {
            parts.append(ActivityFormat.uptime(since: running.started))
        } else {
            parts.append("idle")
        }
        if pane.processes.count > 1 { parts.append("\(pane.processes.count) processes") }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var disclosure: some View {
        if pane.processes.count > 1 {
            Button { withAnimation(.smooth(duration: 0.2)) { activity.toggleExpanded(pane.paneID) } } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: Metrics.activityDisclosureWidth, height: Metrics.activityPaneRowHeight)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(foreground.opacity(0.5))
        } else {
            Color.clear.frame(width: Metrics.activityDisclosureWidth)
        }
    }
}
