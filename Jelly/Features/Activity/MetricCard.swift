import SwiftUI

struct MetricCard<Value: View, Graph: View>: View {
    let title: String
    let detail: String
    let foreground: Color
    var detailColor: Color?
    @ViewBuilder let value: Value
    @ViewBuilder let graph: Graph

    var body: some View {
        HStack(spacing: Metrics.activityCardPadding) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: Metrics.statusFontSize, weight: .semibold))
                    .foregroundStyle(foreground.opacity(0.5))
                value
                    .font(.system(size: Metrics.activityValueFontSize, weight: .semibold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.system(size: Metrics.statusFontSize).monospacedDigit())
                    .foregroundStyle(detailColor ?? foreground.opacity(0.45))
                    .lineLimit(1)
            }
            .frame(width: Metrics.activityCardLabelWidth, alignment: .leading)
            graph
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(Metrics.activityCardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metrics.activityCardCornerRadius, style: .continuous)
                .fill(foreground.opacity(0.045))
        }
    }
}
