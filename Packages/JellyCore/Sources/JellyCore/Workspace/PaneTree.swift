import CoreGraphics
import Foundation

public struct PaneID: Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

public indirect enum PaneTree: Equatable, Sendable, Codable {
    public enum Axis: String, Sendable, Codable {
        case horizontal
        case vertical
    }

    case leaf(PaneID)
    case split(id: UUID, axis: Axis, ratio: Double, first: PaneTree, second: PaneTree)

    public static let ratioBounds = 0.1...0.9

    public var panes: [PaneID] {
        switch self {
        case .leaf(let id): [id]
        case .split(_, _, _, let first, let second): first.panes + second.panes
        }
    }

    public func contains(_ pane: PaneID) -> Bool {
        switch self {
        case .leaf(let id): id == pane
        case .split(_, _, _, let first, let second): first.contains(pane) || second.contains(pane)
        }
    }

    public func splitting(_ pane: PaneID, axis: Axis, with newPane: PaneID) -> PaneTree {
        switch self {
        case .leaf(let id) where id == pane:
            .split(id: UUID(), axis: axis, ratio: 0.5, first: self, second: .leaf(newPane))
        case .leaf:
            self
        case .split(let id, let splitAxis, let ratio, let first, let second):
            .split(
                id: id,
                axis: splitAxis,
                ratio: ratio,
                first: first.splitting(pane, axis: axis, with: newPane),
                second: second.splitting(pane, axis: axis, with: newPane)
            )
        }
    }

    public func removing(_ pane: PaneID) -> PaneTree? {
        switch self {
        case .leaf(let id):
            return id == pane ? nil : self
        case .split(let id, let axis, let ratio, let first, let second):
            guard let newFirst = first.removing(pane) else { return second }
            guard let newSecond = second.removing(pane) else { return first }
            return .split(id: id, axis: axis, ratio: ratio, first: newFirst, second: newSecond)
        }
    }

    public func settingRatio(_ ratio: Double, forSplit splitID: UUID) -> PaneTree {
        switch self {
        case .leaf:
            return self
        case .split(let id, let axis, let current, let first, let second):
            let clamped = min(max(ratio, Self.ratioBounds.lowerBound), Self.ratioBounds.upperBound)
            return .split(
                id: id,
                axis: axis,
                ratio: id == splitID ? clamped : current,
                first: first.settingRatio(ratio, forSplit: splitID),
                second: second.settingRatio(ratio, forSplit: splitID)
            )
        }
    }

    public func equalized() -> PaneTree {
        switch self {
        case .leaf:
            return self
        case .split(let id, let axis, _, let first, let second):
            let firstCount = Double(first.count(along: axis))
            let secondCount = Double(second.count(along: axis))
            return .split(
                id: id,
                axis: axis,
                ratio: firstCount / (firstCount + secondCount),
                first: first.equalized(),
                second: second.equalized()
            )
        }
    }

    private func count(along axis: Axis) -> Int {
        switch self {
        case .leaf: 1
        case .split(_, let splitAxis, _, let first, let second):
            splitAxis == axis ? first.count(along: axis) + second.count(along: axis) : 1
        }
    }

    public func frames(in rect: CGRect) -> [PaneID: CGRect] {
        switch self {
        case .leaf(let id):
            return [id: rect]
        case .split(_, let axis, let ratio, let first, let second):
            let (a, b) = Self.divide(rect, axis: axis, ratio: ratio)
            return first.frames(in: a).merging(second.frames(in: b)) { lhs, _ in lhs }
        }
    }

    static func divide(_ rect: CGRect, axis: Axis, ratio: Double) -> (CGRect, CGRect) {
        switch axis {
        case .horizontal:
            let width = rect.width * ratio
            return (
                CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height),
                CGRect(x: rect.minX + width, y: rect.minY, width: rect.width - width, height: rect.height)
            )
        case .vertical:
            let height = rect.height * ratio
            return (
                CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
                CGRect(x: rect.minX, y: rect.minY + height, width: rect.width, height: rect.height - height)
            )
        }
    }

    public func neighbor(of pane: PaneID, toward direction: KeyAction.Direction) -> PaneID? {
        let frames = frames(in: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let origin = frames[pane] else { return nil }
        let epsilon = 1e-9

        let candidates = frames.filter { id, frame in
            guard id != pane else { return false }
            switch direction {
            case .left: return abs(frame.maxX - origin.minX) < epsilon && Self.overlaps(frame.minY...frame.maxY, origin.minY...origin.maxY)
            case .right: return abs(frame.minX - origin.maxX) < epsilon && Self.overlaps(frame.minY...frame.maxY, origin.minY...origin.maxY)
            case .up: return abs(frame.maxY - origin.minY) < epsilon && Self.overlaps(frame.minX...frame.maxX, origin.minX...origin.maxX)
            case .down: return abs(frame.minY - origin.maxY) < epsilon && Self.overlaps(frame.minX...frame.maxX, origin.minX...origin.maxX)
            }
        }
        let anchor = direction == .left || direction == .right ? origin.minY : origin.minX
        return candidates.min { lhs, rhs in
            let l = direction == .left || direction == .right ? lhs.value.minY : lhs.value.minX
            let r = direction == .left || direction == .right ? rhs.value.minY : rhs.value.minX
            return abs(l - anchor) < abs(r - anchor)
        }?.key
    }

    private static func overlaps(_ a: ClosedRange<CGFloat>, _ b: ClosedRange<CGFloat>) -> Bool {
        min(a.upperBound, b.upperBound) - max(a.lowerBound, b.lowerBound) > 1e-9
    }
}
