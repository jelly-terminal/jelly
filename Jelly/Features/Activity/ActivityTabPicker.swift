import JellyCore
import SwiftUI

struct ActivityTabPicker: View {
    @Binding var selection: ActivityTab
    let theme: Theme

    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ActivityTab.allCases) { tab in
                let isSelected = tab == selection
                Button {
                    withAnimation(.smooth(duration: 0.22)) { selection = tab }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: Metrics.statusFontSize, weight: .medium))
                        Text(tab.title)
                    }
                    .font(.system(size: Metrics.chromeFontSize, weight: .medium))
                    .foregroundStyle(foreground.opacity(isSelected ? 0.95 : 0.5))
                    .padding(.horizontal, Metrics.activityTabPadding)
                    .frame(height: Metrics.activityTabHeight)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(foreground.opacity(0.1))
                                .matchedGeometryEffect(id: "selection", in: highlight)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Capsule().fill(foreground.opacity(0.045)))
    }

    private var foreground: Color {
        Color(theme.foreground)
    }
}
