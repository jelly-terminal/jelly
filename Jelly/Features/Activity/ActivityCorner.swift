import SwiftUI

enum ActivityCorner: String, CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    var isLeading: Bool { self == .topLeading || self == .bottomLeading }
    var isTop: Bool { self == .topLeading || self == .topTrailing }

    var alignment: Alignment {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    var unitPoint: UnitPoint {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    func center(of card: CGSize, in container: CGSize) -> CGPoint {
        CGPoint(
            x: isLeading ? card.width / 2 : container.width - card.width / 2,
            y: isTop ? card.height / 2 : container.height - card.height / 2
        )
    }

    static func nearest(to point: CGPoint, in container: CGSize) -> ActivityCorner {
        switch (point.x < container.width / 2, point.y < container.height / 2) {
        case (true, true): .topLeading
        case (false, true): .topTrailing
        case (true, false): .bottomLeading
        case (false, false): .bottomTrailing
        }
    }
}
