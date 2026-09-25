import AppKit
import JellyCore
import SwiftUI

struct PortRow: View {
    let port: ListeningPort
    let location: PaneLocation?
    let activity: ActivityModel
    let theme: Theme
    let onReveal: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Text(":" + String(port.port))
                .font(.system(size: Metrics.chromeFontSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent)
                .lineLimit(1)
                .frame(minWidth: Metrics.activityPortWidth, minHeight: Metrics.activityPortHeight)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.activityPortCornerRadius, style: .continuous)
                        .fill(accent.opacity(0.14))
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(port.command)
                    .font(.system(size: Metrics.chromeFontSize + 0.5, weight: .medium))
                    .foregroundStyle(foreground.opacity(0.95))
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 5) {
                    if let location {
                        Circle()
                            .fill(location.session.color.color(theme))
                            .frame(width: Metrics.activitySessionDot, height: Metrics.activitySessionDot)
                        Text("\(location.session.name) › \(location.tab.displayTitle)")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("pid \(String(port.pid))")
                    }
                    if port.isExposed {
                        Label("Network", systemImage: "globe")
                            .labelStyle(ExposedLabelStyle())
                            .foregroundStyle(Color(theme.palette[3]).opacity(0.9))
                            .help("Listening on every interface, so other devices on your network can reach it")
                    }
                }
                .font(.system(size: Metrics.statusFontSize))
                .foregroundStyle(foreground.opacity(0.45))
            }
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                if let onReveal {
                    IconButton(symbol: "apple.terminal", help: "Show Pane", theme: theme, action: onReveal)
                }
                IconButton(symbol: "arrow.up.right", help: "Open \(port.url)", theme: theme, action: open)
            }
        }
        .padding(.horizontal, Metrics.activityRowPadding)
        .frame(height: Metrics.activityPaneRowHeight)
        .activityRowBackground(foreground)
        .onTapGesture(perform: open)
        .contextMenu {
            Button("Open in Browser", systemImage: "safari", action: open)
            Button("Copy URL", systemImage: "link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(port.url, forType: .string)
            }
            Divider()
            ProcessMenu(pid: port.pid, activity: activity, onReveal: onReveal)
        }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }

    private var accent: Color {
        Color(theme.accent)
    }

    private func open() {
        guard let url = URL(string: port.url) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct ExposedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon.imageScale(.small)
            configuration.title
        }
    }
}
