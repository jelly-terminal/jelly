import SwiftUI

struct DirectoryBadge: View {
    let path: String
    let foreground: Color
    let accent: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: path == "~" ? "house.fill" : "folder.fill")
                .font(.system(size: Metrics.statusFontSize - 1))
                .foregroundStyle(accent)
            Text(path)
                .font(.system(size: Metrics.statusFontSize + 0.5, weight: .medium, design: .monospaced))
                .foregroundStyle(foreground.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.horizontal, Metrics.quickTerminalBadgePadding)
        .frame(height: Metrics.quickTerminalBadgeHeight)
        .background(Capsule().fill(accent.opacity(0.16)))
        .overlay(Capsule().strokeBorder(accent.opacity(0.28), lineWidth: 1))
        .fixedSize()
    }
}
