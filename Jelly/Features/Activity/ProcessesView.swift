import JellyCore
import SwiftUI

struct ProcessesView: View {
    let activity: ActivityModel
    let window: WindowModel
    let theme: Theme

    var body: some View {
        if let snapshot = activity.snapshot {
            let locations = Dictionary(window.agentPanes.map { ($0.pane.id, $0) }, uniquingKeysWith: { first, _ in first })
            let panes = snapshot.panes.filter { !$0.isIdle } + snapshot.panes.filter(\.isIdle)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ActivitySectionHeader(title: "Jelly", foreground: foreground, showsColumns: true)
                    ForEach(panes) { pane in
                        let isExpanded = activity.expandedPanes.contains(pane.paneID)
                        PaneActivityRow(
                            pane: pane,
                            location: locations[pane.paneID],
                            isExpanded: isExpanded,
                            activity: activity,
                            theme: theme,
                            onReveal: { window.reveal(pane.paneID) }
                        )
                        if isExpanded {
                            ForEach(pane.processes) { process in
                                ProcessActivityRow(
                                    process: process,
                                    indent: Metrics.activityDisclosureWidth + 6 + CGFloat(process.depth) * Metrics.activityIndent,
                                    activity: activity,
                                    theme: theme
                                )
                            }
                            .transition(.opacity)
                        }
                    }
                    if !snapshot.others.isEmpty {
                        ActivitySectionHeader(title: "Other", foreground: foreground)
                        ForEach(snapshot.others) { process in
                            ProcessActivityRow(process: process, indent: 0, activity: activity, theme: theme)
                        }
                    }
                }
                .padding(Metrics.activityPadding)
            }
            .scrollIndicators(.never)
        } else {
            ActivityPlaceholder(symbol: nil, message: "Reading processes…", foreground: foreground)
        }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }
}
