import SwiftUI

struct ActivityRowBackground: ViewModifier {
    let foreground: Color

    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background {
                if isHovered {
                    RoundedRectangle(cornerRadius: Metrics.activityRowCornerRadius, style: .continuous)
                        .fill(foreground.opacity(0.07))
                }
            }
            .contentShape(.rect)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func activityRowBackground(_ foreground: Color) -> some View {
        modifier(ActivityRowBackground(foreground: foreground))
    }
}
