import AppKit

final class TrafficLights {
    private weak var window: NSWindow?
    private let height: CGFloat
    private let leading: CGFloat
    private let spacing: CGFloat
    private var observers: [NSObjectProtocol] = []
    private var isApplying = false

    private static let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

    init(window: NSWindow, height: CGFloat, leading: CGFloat, spacing: CGFloat) {
        self.window = window
        self.height = height
        self.leading = leading
        self.spacing = spacing
        observe()
        apply()
    }

    isolated deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func observe() {
        guard let window, let close = window.standardWindowButton(.closeButton), let container = close.superview?.superview else { return }
        let views = Self.buttonTypes.compactMap { window.standardWindowButton($0) } + [container]
        for view in views {
            view.postsFrameChangedNotifications = true
            observers.append(NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: view,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.apply() }
            })
        }
    }

    func apply() {
        guard !isApplying, let window, !window.styleMask.contains(.fullScreen),
              let close = window.standardWindowButton(.closeButton),
              let titlebar = close.superview,
              let container = titlebar.superview
        else { return }
        isApplying = true
        defer { isApplying = false }

        let containerFrame = NSRect(x: 0, y: window.frame.height - height, width: window.frame.width, height: height)
        if container.frame != containerFrame { container.frame = containerFrame }
        if titlebar.frame != container.bounds { titlebar.frame = container.bounds }

        for (index, type) in Self.buttonTypes.enumerated() {
            guard let button = window.standardWindowButton(type) else { continue }
            let size = button.frame.size
            let origin = NSPoint(
                x: leading + CGFloat(index) * (size.width + spacing),
                y: ((height - size.height) / 2).rounded()
            )
            if button.frame.origin != origin { button.setFrameOrigin(origin) }
        }
    }
}
