import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(configStore: ConfigStore, updatesAvailable: Bool, onCheckForUpdates: @escaping () -> Void, onImportTheme: @escaping () -> Void) {
        let tabs = NSTabViewController()
        tabs.tabStyle = .toolbar

        func add(_ title: String, symbol: String, _ view: some View) {
            let hosting = NSHostingController(rootView: view)
            hosting.title = title
            let item = NSTabViewItem(viewController: hosting)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            tabs.addTabViewItem(item)
        }

        add("General", symbol: "gearshape", GeneralSettingsView(configStore: configStore))
        add("Appearance", symbol: "paintpalette", AppearanceSettingsView(configStore: configStore, onImportTheme: onImportTheme))
        add("Terminal", symbol: "apple.terminal", TerminalSettingsView(configStore: configStore))
        add("Keybinds", symbol: "keyboard", KeybindSettingsView(configStore: configStore))
        add("Updates", symbol: "arrow.triangle.2.circlepath", UpdatesSettingsView(
            configStore: configStore,
            updatesAvailable: updatesAvailable,
            onCheckNow: onCheckForUpdates
        ))

        let window = NSWindow(contentViewController: tabs)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("JellySettingsWindow")
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
}
