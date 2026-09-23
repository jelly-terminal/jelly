import AppKit
import JellyCore
import JellyTerminal
import SwiftUI

struct TerminalHost: NSViewRepresentable {
    let surfaces: [TerminalSurface]
    let cards: [PaneID: CGRect]
    let padding: CGSize
    let focused: TerminalSurface?
    let onFocus: (PaneID) -> Void

    func makeNSView(context: Context) -> TerminalContainerView {
        TerminalContainerView()
    }

    func updateNSView(_ container: TerminalContainerView, context: Context) {
        container.onFocus = onFocus
        container.show(surfaces: surfaces, cards: cards, padding: padding, focused: focused)
    }
}

final class TerminalContainerView: NSView {
    var onFocus: ((PaneID) -> Void)?

    private weak var focused: TerminalSurface?
    private var cards: [PaneID: CGRect] = [:]
    private var responderObservation: NSKeyValueObservation?

    override var isFlipped: Bool { true }

    func show(surfaces: [TerminalSurface], cards: [PaneID: CGRect], padding: CGSize, focused: TerminalSurface?) {
        self.cards = cards
        for view in subviews where !surfaces.contains(where: { $0 === view }) {
            view.removeFromSuperview()
        }
        for surface in surfaces {
            if surface.superview !== self { addSubview(surface) }
            guard let card = cards[surface.paneID] else {
                surface.isHidden = true
                continue
            }
            let frame = PaneLayout.surfaceFrame(in: card, padding: padding)
            if surface.frame != frame { surface.frame = frame }
            surface.isHidden = false
        }
        if self.focused !== focused {
            self.focused = focused
            if let focused { window?.makeFirstResponder(focused) }
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        guard hit === self else { return hit }
        return pane(at: convert(point, from: superview)) == nil ? nil : self
    }

    override func mouseDown(with event: NSEvent) {
        guard let id = pane(at: convert(event.locationInWindow, from: nil)),
              let surface = subviews.first(where: { ($0 as? TerminalSurface)?.paneID == id })
        else { return }
        window?.makeFirstResponder(surface)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        responderObservation = window?.observe(\.firstResponder, options: [.new]) { [weak self] window, _ in
            MainActor.assumeIsolated { self?.responderChanged(window.firstResponder) }
        }
        if let focused { window?.makeFirstResponder(focused) }
    }

    private func responderChanged(_ responder: NSResponder?) {
        guard let surface = responder as? TerminalSurface, surface.superview === self, !surface.isHidden else { return }
        focused = surface
        onFocus?(surface.paneID)
    }

    private func pane(at point: CGPoint) -> PaneID? {
        cards.first { _, card in
            card.contains(point) && point.y > card.minY + Metrics.paneHeaderHeight
        }?.key
    }
}
