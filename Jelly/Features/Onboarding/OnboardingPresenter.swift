import AppKit
import JellyCore
import SwiftUI

final class OnboardingPresenter {
    private let configStore: ConfigStore
    private var window: NSWindow?
    private var onFinish: (() -> Void)?
    private var closeObserver: NSObjectProtocol?

    init(configStore: ConfigStore) {
        self.configStore = configStore
    }

    func present(onFinish: (() -> Void)? = nil) {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }
        self.onFinish = onFinish
        let theme = configStore.theme
        let view = OnboardingView(theme: theme, keybinds: configStore.config.keybinds) { [weak self] in
            self?.window?.close()
        }
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: theme.appearance == .dark ? .darkAqua : .aqua)
        window.center()
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.finish() }
        }
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    private func finish() {
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
        closeObserver = nil
        window = nil
        let onFinish = onFinish
        self.onFinish = nil
        onFinish?()
    }
}
