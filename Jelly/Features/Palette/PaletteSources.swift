
enum PaletteSources {
    static let all: [any PaletteSource] = [
        ActionPaletteSource(),
        AgentPaletteSource(),
        TabPaletteSource(),
        SessionPaletteSource(),
        ThemePaletteSource(),
    ]
}
