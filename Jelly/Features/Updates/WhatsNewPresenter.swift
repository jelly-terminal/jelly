import AppKit
import JellyCore
import JellyTerminal
import SwiftUI

final class WhatsNewPresenter {
    private static let lastLaunchedVersionKey = "lastLaunchedVersion"

    private let configStore: ConfigStore
    private var window: NSWindow?

    init(configStore: ConfigStore) {
        self.configStore = configStore
    }

    var isFirstLaunch: Bool {
        UserDefaults.standard.string(forKey: Self.lastLaunchedVersionKey) == nil
    }

    func presentIfUpdated() {
        let defaults = UserDefaults.standard
        let version = AppInfo.version
        guard let last = defaults.string(forKey: Self.lastLaunchedVersionKey) else {
            defaults.set(version, forKey: Self.lastLaunchedVersionKey)
            return
        }
        guard last != version else { return }
        Task {
            guard let document = await ReleaseNotesLoader.load(version: version) else { return }
            defaults.set(version, forKey: Self.lastLaunchedVersionKey)
            present(document, version: version)
        }
    }

    func present() {
        let version = AppInfo.version
        Task {
            guard let document = await ReleaseNotesLoader.load(version: version) else {
                let alert = NSAlert()
                alert.messageText = "Release notes unavailable"
                alert.informativeText = "Couldn’t load the notes for \(AppInfo.name) \(version). Check your connection and try again."
                alert.runModal()
                return
            }
            present(document, version: version)
        }
    }

    private func present(_ document: MarkdownDocument, version: String) {
        window?.close()
        let theme = configStore.theme
        let codeFont = FontResolver.resolve(configStore.settings.font, size: Metrics.markdownCodeSize).font
        let style = MarkdownStyle(theme: theme, codeFont: codeFont, baseURL: URL(filePath: "/"))
        let view = WhatsNewView(version: version, document: document, style: style) { [weak self] in
            self?.window?.close()
        }
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable]
        window.title = "What’s New"
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: theme.appearance == .dark ? .darkAqua : .aqua)
        window.setContentSize(controller.view.fittingSize)
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
}
