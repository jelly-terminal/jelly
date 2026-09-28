import AppKit
import SwiftUI

struct SelectableText: NSViewRepresentable {
    let text: NSAttributedString
    var wraps = true
    var isSelectable = true
    var decorations: [TextDecoration] = []
    var linkColor: NSColor?
    var anchors: [Int: NSRange] = [:]
    var onAnchors: (([Int: CGRect]) -> Void)?

    @Environment(\.openURL) private var openURL
    @Environment(\.textKeyHandler) private var keyHandler

    func makeNSView(context: Context) -> SelectableTextView {
        SelectableTextView()
    }

    func updateNSView(_ view: SelectableTextView, context: Context) {
        if view.textStorage?.isEqual(to: text) != true {
            view.setText(text)
        }
        view.wraps = wraps
        view.isSelectable = isSelectable
        view.decorations = decorations
        if let linkColor {
            view.linkTextAttributes = [.foregroundColor: linkColor, .cursor: NSCursor.pointingHand]
        }
        let openURL = openURL
        view.onLink = { openURL($0) }
        view.onKey = keyHandler
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: SelectableTextView, context: Context) -> CGSize? {
        let size = nsView.fittingSize(for: proposal.width)
        if let onAnchors, !anchors.isEmpty {
            let rects = anchors.compactMapValues(nsView.rect)
            DispatchQueue.main.async { onAnchors(rects) }
        }
        return size
    }
}
