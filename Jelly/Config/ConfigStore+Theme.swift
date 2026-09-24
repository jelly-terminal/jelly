import JellyCore

extension ConfigStore {
    func apply(_ theme: Theme) {
        switch config.settings.theme {
        case .adaptive(let light, let dark):
            if theme.appearance == .dark {
                setAdaptiveTheme(light: light, dark: theme.id)
            } else {
                setAdaptiveTheme(light: theme.id, dark: dark)
            }
        case .fixed:
            set(.string(theme.id), at: ["settings", "theme"])
        }
    }

    func setAdaptiveTheme(light: String, dark: String) {
        set(.inlineTable(["light": .string(light), "dark": .string(dark)]), at: ["settings", "theme"])
    }
}
