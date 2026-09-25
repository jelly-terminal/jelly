import SwiftUI

struct Sparkline: View {
    let values: [Double]
    let maximum: Double
    let color: Color
    var capacity = ActivityHistory.capacity

    var body: some View {
        Canvas { context, size in
            guard values.count > 1, capacity > 1, maximum > 0 else { return }
            let step = size.width / CGFloat(capacity - 1)
            let start = CGFloat(capacity - values.count) * step
            let inset = Metrics.activitySparklineWidth
            let points = values.enumerated().map { index, value in
                CGPoint(
                    x: start + CGFloat(index) * step,
                    y: size.height - inset - CGFloat(min(max(value / maximum, 0), 1)) * (size.height - inset * 2)
                )
            }
            var line = Path()
            line.addLines(points)
            var area = line
            area.addLine(to: CGPoint(x: points[points.count - 1].x, y: size.height))
            area.addLine(to: CGPoint(x: points[0].x, y: size.height))
            area.closeSubpath()
            context.fill(area, with: .linearGradient(
                Gradient(colors: [color.opacity(0.3), color.opacity(0.02)]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height)
            ))
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: inset, lineCap: .round, lineJoin: .round))
        }
    }
}
