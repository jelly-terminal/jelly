import Foundation

public enum BuiltinThemes {
    public static let darkID = "jelly-dark"
    public static let lightID = "jelly-light"

    public static let all: [Theme] = {
        guard let directory = Bundle.module.url(forResource: "Themes", withExtension: nil),
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [fallback] }
        let themes = files
            .filter { $0.pathExtension == "toml" }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .flatMap { ConfigDocument(parsing: $0).themes }
        return themes.isEmpty ? [fallback] : themes
    }()

    public static let fallback = Theme(
        id: darkID,
        name: "Jelly Dark",
        background: RGBColor(red: 14, green: 17, blue: 23),
        foreground: RGBColor(red: 213, green: 219, blue: 229),
        palette: [
            "#1c2230", "#ff6b7f", "#7ee2a8", "#f2c46d", "#6ea8ff", "#c08cff", "#5fd4e6", "#c9d1dc",
            "#5b6577", "#ff8a9a", "#9af0bf", "#ffd78c", "#8fbcff", "#d4a9ff", "#86e3f0", "#ffffff",
        ].compactMap(RGBColor.init(hex:))
    )
}
