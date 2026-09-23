import Foundation

public struct Config: Sendable {
    public var settings: Settings
    public var keybinds: Keybinds
    public var themes: [String: Theme]
    public var diagnostics: [Diagnostic]

    public init(settings: Settings = Settings(), keybinds: Keybinds = Keybinds(), themes: [String: Theme] = [:], diagnostics: [Diagnostic] = []) {
        self.settings = settings
        self.keybinds = keybinds
        self.themes = themes
        self.diagnostics = diagnostics
    }

    public var sortedThemes: [Theme] {
        themes.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func theme(dark: Bool) -> Theme {
        let id = settings.theme.id(dark: dark)
        if let theme = themes[id] { return theme }
        let fallback = dark ? BuiltinThemes.darkID : BuiltinThemes.lightID
        return themes[fallback] ?? BuiltinThemes.fallback
    }

    public func missingThemeDiagnostic(dark: Bool) -> Diagnostic? {
        let id = settings.theme.id(dark: dark)
        return themes[id] == nil ? Diagnostic(message: "settings.theme: no theme with id '\(id)'") : nil
    }
}
