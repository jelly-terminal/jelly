
struct PaletteMatch: Identifiable {
    let item: PaletteItem
    let section: String
    var score = 0
    var positions: [Int] = []

    var id: String { item.id }
}
