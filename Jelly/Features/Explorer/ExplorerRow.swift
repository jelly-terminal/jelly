struct ExplorerRow: Identifiable {
    let entry: ExplorerEntry
    let depth: Int
    let isExpanded: Bool

    var id: ExplorerEntry.ID { entry.id }
}
