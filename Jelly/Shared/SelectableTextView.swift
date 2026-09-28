import AppKit

final class SelectableTextView: NSTextView {
    var wraps = true
    var decorations: [TextDecoration] = [] {
        didSet { if decorations != oldValue { needsDisplay = true } }
    }
    var onLink: ((URL) -> Void)?
    var onKey: ((NSEvent) -> Bool)?

    convenience init() {
        self.init(usingTextLayoutManager: false)
        isEditable = false
        isSelectable = true
        isRichText = true
        drawsBackground = false
        isVerticallyResizable = false
        isHorizontallyResizable = false
        textContainerInset = .zero
        textContainer?.lineFragmentPadding = 0
        textContainer?.widthTracksTextView = false
        textContainer?.heightTracksTextView = false
        layoutManager?.allowsNonContiguousLayout = true
        usesFindBar = false
        isAutomaticLinkDetectionEnabled = false
    }

    func fittingSize(for width: CGFloat?) -> CGSize {
        guard let textContainer, let layoutManager else { return .zero }
        let containerWidth = wraps ? max(width ?? Metrics.markdownMaxWidth, 1) : .greatestFiniteMagnitude
        if textContainer.size.width != containerWidth {
            textContainer.size = CGSize(width: containerWidth, height: .greatestFiniteMagnitude)
        }
        layoutManager.ensureLayout(for: textContainer)
        let used = layoutManager.usedRect(for: textContainer)
        return CGSize(width: wraps ? containerWidth : ceil(used.width), height: ceil(used.height))
    }

    func rect(of range: NSRange) -> CGRect? {
        guard let layoutManager, let textContainer, range.location < textStorage?.length ?? 0 else { return nil }
        let glyphs = layoutManager.glyphRange(forCharacterRange: NSRange(location: range.location, length: max(range.length, 1)), actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphs, in: textContainer)
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        if wraps, let textContainer, textContainer.size.width != newSize.width {
            textContainer.size = CGSize(width: newSize.width, height: .greatestFiniteMagnitude)
        }
    }

    override func keyDown(with event: NSEvent) {
        if onKey?(event) == true { return }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        if let event = NSApp.currentEvent, onKey?(event) == true { return }
        super.cancelOperation(sender)
    }

    override func clicked(onLink link: Any, at charIndex: Int) {
        let url = (link as? URL) ?? (link as? String).flatMap { URL(string: $0) }
        guard let url, let onLink else { return super.clicked(onLink: link, at: charIndex) }
        onLink(url)
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        for decoration in decorations {
            switch decoration {
            case .underline(let range, let color):
                guard let bounds = self.rect(of: range) else { continue }
                color.setFill()
                NSRect(x: 0, y: bounds.maxY + 5, width: self.bounds.width, height: 1).fill()
            case .bar(let range, let x, let width, let color):
                guard let bounds = self.rect(of: range) else { continue }
                color.setFill()
                NSBezierPath(roundedRect: NSRect(x: x, y: bounds.minY, width: width, height: bounds.height), xRadius: width / 2, yRadius: width / 2).fill()
            case .box(let range, let x, let padding, let cornerRadius, let color):
                guard let bounds = self.rect(of: range) else { continue }
                color.setFill()
                let box = NSRect(x: x, y: bounds.minY - padding, width: self.bounds.width - x, height: bounds.height + padding * 2)
                NSBezierPath(roundedRect: box, xRadius: cornerRadius, yRadius: cornerRadius).fill()
            case .rule(let range, let color):
                guard let bounds = self.rect(of: range) else { continue }
                color.setFill()
                NSRect(x: 0, y: bounds.midY.rounded(), width: self.bounds.width, height: 1).fill()
            }
        }
    }
}
