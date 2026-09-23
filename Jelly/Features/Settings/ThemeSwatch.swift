import JellyCore
import SwiftUI

struct ThemeSwatch: View {
    let theme: Theme

    var body: some View {
        HStack(spacing: 8) {
            Text("Aa")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(theme.foreground))
            HStack(spacing: 4) {
                ForEach(1..<7, id: \.self) { index in
                    Circle()
                        .fill(Color(theme.palette[index]))
                        .frame(width: Metrics.themeSwatchDot, height: Metrics.themeSwatchDot)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: Metrics.themeSwatchHeight)
        .background(Color(theme.background), in: .rect(cornerRadius: Metrics.sidebarRowCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.sidebarRowCornerRadius)
                .strokeBorder(.separator)
        }
    }
}
