import AppKit
import SwiftUI

final class ActivationWindowController: NSWindowController {
    private var onActivated: (() -> Void)?

    init(license: LicenseService, reason: String, onActivated: @escaping () -> Void) {
        self.onActivated = onActivated
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Activate \(AppInfo.name)"
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)

        window.contentViewController = NSHostingController(
            rootView: LicenseSheet(
                license: license,
                reason: reason,
                dismissTitle: "Quit",
                onActivated: { [weak self] in self?.finish() },
                onDismiss: { NSApp.terminate(nil) }
            )
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    private func finish() {
        onActivated?()
        onActivated = nil
        close()
    }
}
