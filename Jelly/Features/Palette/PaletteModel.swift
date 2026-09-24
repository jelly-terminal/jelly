import AppKit
import JellyCore
import Observation

@Observable
final class PaletteModel {
    static let recentSection = "Recent"
    private static let recentLimit = 5
    private static let keywordPenalty = 4
    private static var recentIDs: [String] = []

    var query = "" {
        didSet { refresh() }
    }
    private(set) var matches: [PaletteMatch] = []
    var selectedID: String? {
        didSet {
            guard selectedID != oldValue else { return }
            updatePreview()
        }
    }

    @ObservationIgnored private let entries: [PaletteMatch]
    @ObservationIgnored private let onRun: (PaletteItem, (() -> Void)?) -> Void
    @ObservationIgnored private var revertPreview: (() -> Void)?

    init(window: WindowModel, sources: [any PaletteSource], onRun: @escaping (PaletteItem, (() -> Void)?) -> Void) {
        entries = sources.flatMap { source in
            source.items(in: window).map { PaletteMatch(item: $0, section: source.section) }
        }
        self.onRun = onRun
        refresh()
    }

    var isFiltering: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func moveSelection(by offset: Int) {
        guard !matches.isEmpty else { return }
        let index = matches.firstIndex { $0.id == selectedID } ?? -offset
        selectedID = matches[min(max(index + offset, 0), matches.count - 1)].id
    }

    func runSelection() {
        guard let match = matches.first(where: { $0.id == selectedID }) else {
            NSSound.beep()
            return
        }
        run(match.item)
    }

    func run(_ item: PaletteItem) {
        Self.recentIDs.removeAll { $0 == item.id }
        Self.recentIDs.insert(item.id, at: 0)
        Self.recentIDs = Array(Self.recentIDs.prefix(Self.recentLimit))
        let revert = revertPreview
        revertPreview = nil
        onRun(item, revert)
    }

    func cancelPreview() {
        revertPreview?()
        revertPreview = nil
    }

    func handle(_ event: NSEvent) -> Bool {
        let control = event.modifierFlags.contains(.control)
        switch event.specialKey {
        case .upArrow?: moveSelection(by: -1)
        case .downArrow?: moveSelection(by: 1)
        case .carriageReturn?, .enter?: runSelection()
        default:
            switch (control, event.charactersIgnoringModifiers) {
            case (true, "p"): moveSelection(by: -1)
            case (true, "n"): moveSelection(by: 1)
            default: return false
            }
        }
        return true
    }

    private func updatePreview() {
        cancelPreview()
        let item = matches.first { $0.id == selectedID }?.item
        revertPreview = item?.preview?()
    }

    private func refresh() {
        matches = isFiltering ? ranked() : grouped()
        selectedID = matches.first?.id
    }

    private func grouped() -> [PaletteMatch] {
        let recents = Self.recentIDs.compactMap { id in
            entries.first { $0.id == id }.map { PaletteMatch(item: $0.item, section: Self.recentSection) }
        }
        let recentIDs = Set(recents.map(\.id))
        return recents + entries.filter { !recentIDs.contains($0.id) }
    }

    private func ranked() -> [PaletteMatch] {
        entries.enumerated()
            .compactMap { offset, entry in score(entry).map { ($0, offset) } }
            .sorted { $0.0.score != $1.0.score ? $0.0.score > $1.0.score : $0.1 < $1.1 }
            .map(\.0)
    }

    private func score(_ entry: PaletteMatch) -> PaletteMatch? {
        let recency = Self.recentIDs.firstIndex(of: entry.id).map { Self.recentLimit - $0 } ?? 0
        if let match = FuzzyMatcher.match(query, in: entry.item.title) {
            return PaletteMatch(item: entry.item, section: entry.section, score: match.score + recency, positions: match.positions)
        }
        let best = entry.item.keywords.compactMap { FuzzyMatcher.match(query, in: $0)?.score }.max()
        return best.map { PaletteMatch(item: entry.item, section: entry.section, score: $0 - Self.keywordPenalty + recency) }
    }
}
