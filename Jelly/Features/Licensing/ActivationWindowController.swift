import AppKit
import SwiftUI

final class ActivationWindowController: NSWindowController {
    private var onActivated: (() -> Void)?

    init(license: LicenseService, onActivated: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onActivated = onActivated
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Activate \(AppInfo.name)"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        [.closeButton, .miniaturizeButton, .zoomButton].forEach { window.standardWindowButton($0)?.isHidden = true }
        super.init(window: window)

        let hosting = NSHostingController(
            rootView: LicenseSheet(
                license: license,
                onActivated: { [weak self] in self?.finish() },
                onDismiss: onDismiss
            )
        )
        hosting.sizingOptions = .preferredContentSize
        window.contentViewController = hosting
        window.setContentSize(hosting.view.fittingSize)
        window.center()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func finish() {
        onActivated?()
        onActivated = nil
        close()
    }
}
