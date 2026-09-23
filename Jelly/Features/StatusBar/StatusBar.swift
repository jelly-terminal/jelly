import JellyCore
import SwiftUI

struct StatusBar: View {
    let sessionName: String
    let tabCount: Int
    let paneCount: Int
    let gridSize: (cols: Int, rows: Int)?
    let theme: Theme

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(theme.palette[2]))
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
