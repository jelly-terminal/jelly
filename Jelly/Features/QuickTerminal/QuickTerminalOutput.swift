import AppKit
import JellyTerminal
import SwiftUI

struct QuickTerminalOutput: NSViewRepresentable {
    let surface: TerminalSurface

    func makeNSView(context: Context) -> OutputClip {
        OutputClip(surface: surface)
    }

    func updateNSView(_ view: OutputClip, context: Context) {}

    final class OutputClip: NSView {
        private let surface: TerminalSurface

        init(surface: TerminalSurface) {
            self.surface = surface
            super.init(frame: .zero)
            wantsLayer = true
            layer?.masksToBounds = true
            addSubview(surface)
        }

        required init?(coder: NSCoder) { fatalError() }

        override var isFlipped: Bool { true }

        override func layout() {
            super.layout()
            surface.setFrameOrigin(.zero)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(surface)
        }
    }
}
