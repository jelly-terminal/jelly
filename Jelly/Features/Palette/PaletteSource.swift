
protocol PaletteSource {
    var section: String { get }
    func items(in window: WindowModel) -> [PaletteItem]
}
