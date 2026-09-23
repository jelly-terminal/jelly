import AppKit
import JellyCore
import Observation

@Observable
final class ConfigStore {
    let paths: ConfigPaths
    private(set) var config = Config()
    private(set) var isDark = true
    private(set) var runtimeDiagnostics: [Diagnostic] = []
    var dismissedDiagnostics: [Diagnostic] = []
    var editError: String?
    var fontSizeDelta = 0.0 {
        didSet { notify() }
    }

    @ObservationIgnored private var watcher: ConfigWatcher?
    @ObservationIgnored private var appearanceObservation: NSKeyValueObservation?
    @ObservationIgnored private var listeners: [UUID: () -> Void] = [:]

    init(paths: ConfigPaths = .standard()) {
        self.paths = paths
        try? ConfigLoader.createConfigFileIfMissing(paths: paths)
        isDark = NSApp.effectiveAppearance.isDark
        config = ConfigLoader.load(paths: paths)
        watcher = ConfigWatcher(paths: paths) { [weak self] in self?.reload() }
        watcher?.start()
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] app, _ in
            MainActor.assumeIsolated {
                guard let self, self.isDark != app.effectiveAppearance.isDark else { return }
                self.isDark = app.effectiveAppearance.isDark
                self.notify()
            }
        }
    }

    var settings: Settings {
        var settings = config.settings
        settings.font.size = min(max(settings.font.size + fontSizeDelta, 6), 72)
        return settings
    }

    var theme: Theme {
        config.theme(dark: isDark)
    }

    var visibleDiagnostics: [Diagnostic] {
        (config.diagnostics + runtimeDiagnostics).filter { !dismissedDiagnostics.contains($0) }
    }

    func reload() {
        config = ConfigLoader.load(paths: paths)
        runtimeDiagnostics = []
        dismissedDiagnostics = []
        notify()
    }

    func report(_ diagnostics: [Diagnostic]) {
        let fresh = diagnostics.filter { !runtimeDiagnostics.contains($0) }
        if !fresh.isEmpty { runtimeDiagnostics += fresh }
    }

    func observe(_ listener: @escaping () -> Void) -> UUID {
        let id = UUID()
        listeners[id] = listener
        return id
    }

    func removeObserver(_ id: UUID) {
        listeners[id] = nil
    }

    func openConfigFile() {
        try? ConfigLoader.createConfigFileIfMissing(paths: paths)
        NSWorkspace.shared.open(paths.configFile)
    }

    func currentConfigText() -> String {
        (try? String(contentsOf: paths.configFile, encoding: .utf8)) ?? ""
    }

    private func notify() {
        listeners.values.forEach { $0() }
    }
}

extension NSAppearance {
    var isDark: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
