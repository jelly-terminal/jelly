import AppKit
import JellyCore
import JellyTerminal
import Observation

@Observable
final class QuickTerminalModel {
    private(set) var surface: TerminalSurface?
    private(set) var rows = 0
    private(set) var directory = NSHomeDirectory()

    @ObservationIgnored let configStore: ConfigStore
    @ObservationIgnored var onOpenInTab: ((TerminalSurface) -> Void)?
    @ObservationIgnored var onContentHeightChange: ((CGFloat) -> Void)?
    @ObservationIgnored var onShellExit: (() -> Void)?

    init(configStore: ConfigStore) {
        self.configStore = configStore
    }

    var theme: Theme {
        configStore.theme
    }

    var displayDirectory: String {
        let path = (directory as NSString).abbreviatingWithTildeInPath
        let components = (path as NSString).pathComponents
        guard components.count > 3 else { return path }
        return "…/" + components.suffix(2).joined(separator: "/")
    }

    var outputHeight: CGFloat {
        guard let surface else { return 0 }
        return CGFloat(min(max(rows, 1), Metrics.quickTerminalOutputRows)) * surface.cellHeight
    }

    var outputWidth: CGFloat {
        Metrics.quickTerminalWidth - Metrics.quickTerminalPadding * 2
    }

    @discardableResult
    func startIfNeeded() -> TerminalSurface {
        if let surface { return surface }
        let settings = configStore.settings
        var shell = settings.shell
        shell.workingDirectory = .path(directory)
        let surface = TerminalSurface(appVersion: AppInfo.version, settings: settings, theme: configStore.theme)
        configStore.report(surface.apply(settings: settings, theme: configStore.theme))
        surface.onContentRowsChange = { [weak self] rows in self?.rows = rows }
        surface.onDirectoryChange = { [weak self] _ in self?.refreshDirectory() }
        surface.onExit = { [weak self, weak surface] _ in
            guard let self, self.surface === surface else { return }
            self.surface = nil
            self.rows = 0
            self.onShellExit?()
        }
        self.surface = surface
        layout(surface)
        surface.start(shell: shell, inheritedDirectory: nil, keepAlive: false, reattach: false)
        return surface
    }

    func refreshDirectory() {
        guard let current = surface?.workingDirectory, current != directory else { return }
        directory = current
    }

    func openInTab() {
        guard let surface else { return }
        refreshDirectory()
        surface.onContentRowsChange = nil
        surface.onDirectoryChange = nil
        surface.onExit = nil
        self.surface = nil
        rows = 0
        surface.removeFromSuperview()
        onOpenInTab?(surface)
    }

    func applyConfig() {
        guard let surface else { return }
        configStore.report(surface.apply(settings: configStore.settings, theme: configStore.theme))
        layout(surface)
    }

    private func layout(_ surface: TerminalSurface) {
        let height = surface.cellHeight * CGFloat(Metrics.quickTerminalOutputRows)
        (surface as NSView).setFrameSize(NSSize(width: outputWidth, height: height))
    }
}
