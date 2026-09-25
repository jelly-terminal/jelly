import JellyCore
import SwiftUI

struct IconButton: View {
    let symbol: String
    let help: String
    let theme: Theme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metrics.paneHeaderIconSize, weight: .medium))
                .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                .background {
                    if isHovered {
                        RoundedRectangle(cornerRadius: Metrics.paneButtonCornerRadius, style: .continuous)
                            .fill(Color(theme.foreground).opacity(0.1))
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.foreground).opacity(isHovered ? 0.9 : 0.55))
        .onHover { isHovered = $0 }
        .help(help)
    }
}
