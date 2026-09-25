import JellyCore
import SwiftUI

struct PortsView: View {
    let activity: ActivityModel
    let window: WindowModel
    let theme: Theme

    var body: some View {
        if let ports = activity.snapshot?.ports {
            if ports.isEmpty {
                ActivityPlaceholder(symbol: "network.slash", message: "Nothing is listening on a port", foreground: foreground)
            } else {
                let locations = Dictionary(window.agentPanes.map { ($0.pane.id, $0) }, uniquingKeysWith: { first, _ in first })
                let jelly = ports.filter { $0.paneID != nil }
                let others = ports.filter { $0.paneID == nil }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !jelly.isEmpty {
                            ActivitySectionHeader(title: "Jelly", foreground: foreground)
                            ForEach(jelly) { port in
                                PortRow(
                                    port: port,
                                    location: port.paneID.flatMap { locations[$0] },
                                    activity: activity,
                                    theme: theme,
                                    onReveal: port.paneID.map { paneID in { window.reveal(paneID) } }
                                )
                            }
                        }
                        if !others.isEmpty {
                            ActivitySectionHeader(title: "Other", foreground: foreground)
                            ForEach(others) { port in
                                PortRow(port: port, location: nil, activity: activity, theme: theme, onReveal: nil)
                            }
                        }
                    }
                    .padding(Metrics.activityPadding)
                }
                .scrollIndicators(.never)
            }
        } else {
            ActivityPlaceholder(symbol: nil, message: "Looking for open ports…", foreground: foreground)
        }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }
}
