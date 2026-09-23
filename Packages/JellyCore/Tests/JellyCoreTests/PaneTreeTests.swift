import Foundation
import Testing
@testable import JellyCore

struct PaneTreeTests {
    let a = PaneID(), b = PaneID(), c = PaneID()

    private var threePanes: PaneTree {
        PaneTree.leaf(a)
            .splitting(a, axis: .vertical, with: b)
            .splitting(b, axis: .horizontal, with: c)
    }

    @Test func splitKeepsOrderAndClosePromotesSibling() {
        let tree = threePanes
        #expect(tree.panes == [a, b, c])
        #expect(tree.removing(b)?.panes == [a, c])
        guard case .split(_, let axis, _, let first, let second)? = tree.removing(a) else { Issue.record(); return }
        #expect(axis == .horizontal && first == .leaf(b) && second == .leaf(c))
        #expect(PaneTree.leaf(a).removing(a) == nil)
    }

    @Test func focusMovesToTheAdjacentPane() {
        let tree = threePanes
        #expect(tree.neighbor(of: a, toward: .down) == b)
        #expect(tree.neighbor(of: b, toward: .right) == c)
        #expect(tree.neighbor(of: c, toward: .left) == b)
        #expect(tree.neighbor(of: c, toward: .up) == a)
        #expect(tree.neighbor(of: a, toward: .left) == nil)
    }

    @Test func ratioIsClampedAndEqualizeCountsPanes() {
        let tree = threePanes
        guard case .split(let id, _, _, _, _) = tree else { Issue.record(); return }
        guard case .split(_, _, let ratio, _, _) = tree.settingRatio(0.99, forSplit: id) else { Issue.record(); return }
        #expect(ratio == PaneTree.ratioBounds.upperBound)

        let row = PaneTree.leaf(a).splitting(a, axis: .horizontal, with: b).splitting(b, axis: .horizontal, with: c)
        let frames = row.equalized().frames(in: CGRect(x: 0, y: 0, width: 300, height: 100))
        #expect(frames.values.map { $0.width.rounded() }.sorted() == [100, 100, 100])
    }
}
