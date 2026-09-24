import JellyCore

struct ThemePaletteSource: PaletteSource {
    let section = "Themes"

    func items(in window: WindowModel) -> [PaletteItem] {
        let configStore = window.configStore
        let current = configStore.theme.id
        return configStore.config.sortedThemes.map { theme in
            PaletteItem(
                id: "theme:" + theme.id,
                title: theme.name,
                subtitle: theme.appearance == .dark ? "Dark theme" : "Light theme",
                symbol: "paintpalette",
                keywords: ["Theme " + theme.name, theme.id],
                isCurrent: theme.id == current,
                preview: {
                    configStore.previewTheme = theme
                    return { configStore.previewTheme = nil }
                }
            ) {
                configStore.apply(theme)
            }
        }
    }
}
