import JellyCore

enum ChangesRow: Identifiable {
    case section(GitChange.Area, count: Int)
    case change(GitChange)

    var id: String {
        switch self {
        case .section(let area, _): "section:\(area.rawValue)"
        case .change(let change): change.id
        }
    }
}
