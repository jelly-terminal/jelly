import JellyCore

struct PaletteItem: Identifiable {
    let id: String
    let title: String
    var subtitle: String?
    var symbol: String?
    var shortcut: KeyChord?
    var keywords: [String] = []
    var isCurrent = false
    var preview: (() -> () -> Void)?
    let perform: () -> Void
}
