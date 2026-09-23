import CoreGraphics
import Foundation
import JellyCore

struct PaneLayout {
    struct Divider: Identifiable {
        let id: UUID
        let axis: PaneTree.Axis
        let frame: CGRect
        let span: CGRect

        func ratio(at location: CGPoint) -> Double {
            switch axis {
            case .horizontal: (location.x - span.minX) / span.width
            case .vertical: (location.y - span.minY) / span.height
            }
        }
    }

    private(set) var cards: [PaneID: CGRect] = [:]
    private(set) var dividers: [Divider] = []

    init(tree: PaneTree, zoomed: PaneID?, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        if let zoomed, tree.contains(zoomed) {
            cards[zoomed] = bounds
            return
        }
        let half = Metrics.paneGap / 2
        place(tree, in: bounds.insetBy(dx: -half, dy: -half))
    }

    static func surfaceFrame(in card: CGRect, padding: CGSize) -> CGRect {
        CGRect(
            x: card.minX + padding.width,
            y: card.minY + Metrics.paneHeaderHeight,
            width: max(0, card.width - padding.width * 2),
            height: max(0, card.height - Metrics.paneHeaderHeight - padding.height)
        )
    }

    private mutating func place(_ tree: PaneTree, in rect: CGRect) {
        let half = Metrics.paneGap / 2
        switch tree {
        case .leaf(let id):
            cards[id] = Self.pixelAligned(rect.insetBy(dx: half, dy: half))
        case .split(let id, let axis, let ratio, let first, let second):
            let (a, b) = PaneTree.divide(rect, axis: axis, ratio: ratio)
            let thickness = Metrics.paneDividerHitWidth
            let frame = switch axis {
            case .horizontal:
                CGRect(x: a.maxX - thickness / 2, y: rect.minY + half, width: thickness, height: rect.height - Metrics.paneGap)
            case .vertical:
                CGRect(x: rect.minX + half, y: a.maxY - thickness / 2, width: rect.width - Metrics.paneGap, height: thickness)
            }
            dividers.append(Divider(id: id, axis: axis, frame: frame, span: rect))
            place(first, in: a)
            place(second, in: b)
        }
    }

    private static func pixelAligned(_ rect: CGRect) -> CGRect {
        let minX = rect.minX.rounded(), minY = rect.minY.rounded()
        return CGRect(x: minX, y: minY, width: rect.maxX.rounded() - minX, height: rect.maxY.rounded() - minY)
    }
}
