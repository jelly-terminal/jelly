import Foundation

public enum ConfigLoader {
    public static func load(paths: ConfigPaths, builtins: [Theme] = BuiltinThemes.all) -> Config {
        var themes = Dictionary(builtins.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        var diagnostics: [Diagnostic] = []

        for url in themeFiles(in: paths.themesDirectory) {
            guard let source = read(url, diagnostics: &diagnostics) else { continue }
            let document = ConfigDocument(parsing: source, file: "themes/\(url.lastPathComponent)")
            diagnostics += document.diagnostics
            for theme in document.themes { themes[theme.id] = theme }
        }

        var config = Config(themes: themes)
        if let source = read(paths.configFile, diagnostics: &diagnostics) {
            let document = ConfigDocument(parsing: source, file: paths.configFile.lastPathComponent)
            diagnostics += document.diagnostics
            for theme in document.themes { config.themes[theme.id] = theme }
            config.settings = document.settings
            config.keybinds = document.keybinds
        }
        for dark in [false, true] {
            if let missing = config.missingThemeDiagnostic(dark: dark), !diagnostics.contains(missing) {
                diagnostics.append(Diagnostic(file: paths.configFile.lastPathComponent, message: missing.message))
            }
        }
        config.diagnostics = diagnostics
        return config
    }

    public static func createConfigFileIfMissing(paths: ConfigPaths) throws {
        let manager = FileManager.default
        try manager.createDirectory(at: paths.themesDirectory, withIntermediateDirectories: true)
        guard !manager.fileExists(atPath: paths.configFile.path) else { return }
        try DefaultConfig.text.write(to: paths.configFile, atomically: true, encoding: .utf8)
    }

    private static func themeFiles(in directory: URL) -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "toml" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func read(_ url: URL, diagnostics: inout [Diagnostic]) -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            diagnostics.append(Diagnostic(file: url.lastPathComponent, message: "could not read file: \(error.localizedDescription)"))
            return nil
        }
    }
}
