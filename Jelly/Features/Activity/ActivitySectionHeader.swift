import SwiftUI

struct ActivitySectionHeader: View {
    let title: String
    let foreground: Color
    var showsColumns = false

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
            Spacer(minLength: 0)
            if showsColumns {
                Text("CPU").frame(width: Metrics.activityCPUColumn, alignment: .trailing)
                Text("Memory").frame(width: Metrics.activityMemoryColumn, alignment: .trailing)
            }
        }
        .font(.system(size: Metrics.statusFontSize, weight: .semibold))
        .foregroundStyle(foreground.opacity(0.45))
        .padding(.horizontal, Metrics.activityRowPadding)
        .frame(height: Metrics.activitySectionHeight, alignment: .bottom)
    }
}
