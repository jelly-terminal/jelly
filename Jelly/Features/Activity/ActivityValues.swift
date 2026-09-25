import SwiftUI

struct ActivityValues: View {
    let cpu: Double
    let memory: UInt64
    let foreground: Color
    let warning: Color

    var body: some View {
        HStack(spacing: 0) {
            Text(ActivityFormat.cpu(cpu))
                .foregroundStyle(cpu >= Self.busyThreshold ? warning : foreground.opacity(cpu < Self.quietThreshold ? 0.4 : 0.75))
                .frame(width: Metrics.activityCPUColumn, alignment: .trailing)
            Text(ActivityFormat.bytes(memory))
                .foregroundStyle(foreground.opacity(0.55))
                .frame(width: Metrics.activityMemoryColumn, alignment: .trailing)
        }
        .font(.system(size: Metrics.statusFontSize).monospacedDigit())
        .lineLimit(1)
    }

    private static let busyThreshold = 80.0
    private static let quietThreshold = 0.5
}
