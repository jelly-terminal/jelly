import AppKit
import JellyTerminal
import SwiftUI

struct TerminalHost: NSViewRepresentable {
    let surfaces: [TerminalSurface]
    let selected: TerminalSurface?

    func makeNSView(context: Context) -> TerminalContainerView {
        TerminalContainerView()
    }

    func updateNSView(_ container: TerminalContainerView, context: Context) {
        container.show(surfaces: surfaces, selected: selected)
    }
}

final class TerminalContainerView: NSView {
    private weak var visible: TerminalSurface?

    func show(surfaces: [TerminalSurface], selected: TerminalSurface?) {
        for view in subviews where !surfaces.contains(where: { $0 === view }) {
            view.removeFromSuperview()
        }
        for surface in surfaces where surface.superview !== self {
            surface.frame = bounds
            surface.autoresizingMask = [.width, .height]
            addSubview(surface)
        }
        for surface in surfaces {
            surface.isHidden = surface !== selected
        }
        if visible !== selected {
            visible = selected
            if let selected { window?.makeFirstResponder(selected) }
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let visible { window?.makeFirstResponder(visible) }
    }
}
