import JellyCore
import SwiftUI

struct ProcessActivityRow: View {
    let process: ProcessActivity
    let indent: CGFloat
    let activity: ActivityModel
    let theme: Theme

    var body: some View {
        HStack(spacing: 6) {
            Text(process.command)
                .font(.system(size: Metrics.chromeFontSize))
                .foregroundStyle(foreground.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)
                .help(process.command)
            Text(String(process.pid))
                .font(.system(size: Metrics.statusFontSize).monospacedDigit())
                .foregroundStyle(foreground.opacity(0.3))
            Spacer(minLength: 8)
            ActivityValues(cpu: process.cpu, memory: process.memory, foreground: foreground, warning: Color(theme.palette[3]))
        }
        .padding(.leading, Metrics.activityRowPadding + indent)
        .padding(.trailing, Metrics.activityRowPadding)
        .frame(height: Metrics.activityRowHeight)
        .activityRowBackground(foreground)
        .contextMenu { ProcessMenu(pid: process.pid, activity: activity) }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }
}
