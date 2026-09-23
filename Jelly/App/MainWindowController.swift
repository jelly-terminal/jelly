import AppKit
import SwiftUI

final class MainWindowController: NSWindowController, NSWindowDelegate {
    var onClose: (() -> Void)?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 320)
        window.setFrameAutosaveName("JellyMainWindow")
        window.contentViewController = NSHostingController(rootView: RootView())
        if window.frame.origin == .zero { window.center() }
        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

struct RootView: View {
    var body: some View {
        Text("Jelly")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
