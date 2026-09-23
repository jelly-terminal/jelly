import JellyCore
import SwiftUI

struct StatusBar: View {
    let tab: TabModel?
    let tabCount: Int
    let theme: Theme

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(theme.palette[2]))
                    .frame(width: 6, height: 6)
                Text(tab?.displayTitle ?? "")
                separator
                Text(tabCount == 1 ? "1 tab" : "\(tabCount) tabs")
                if let size = tab?.gridSize, size.cols > 0 {
                    separator
                    Text("\(size.cols)×\(size.rows)")
                        .monospacedDigit()
                }
            }
            .font(.system(size: Metrics.statusFontSize, weight: .medium))
            .foregroundStyle(Color(theme.foreground).opacity(0.7))
            .padding(.horizontal, 12)
            .frame(height: Metrics.statusBarHeight - 6)
            .glassEffect(.regular, in: .capsule)
        }
        .padding(.horizontal, Metrics.chromePadding)
        .frame(height: Metrics.statusBarHeight)
    }

    private var separator: some View {
        Text("·").opacity(0.5)
    }
}
