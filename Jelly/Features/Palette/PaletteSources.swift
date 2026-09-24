
enum PaletteSources {
    static let all: [any PaletteSource] = [
        ActionPaletteSource(),
        TabPaletteSource(),
        SessionPaletteSource(),
        ProjectPaletteSource(),
        ThemePaletteSource(),
    ]
}
