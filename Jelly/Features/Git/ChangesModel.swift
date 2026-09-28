import Foundation
import JellyCore
import Observation

@Observable
final class ChangesModel {
    enum State {
        case idle, loading, notRepository, gitMissing, ready
    }

    private(set) var repository: URL?
    private(set) var status: GitStatus?
    private(set) var state: State = .idle
    private(set) var decorations = GitDecorations()
    var selection: GitChange.ID?
    var filter = ""

    @ObservationIgnored private var followedDirectory: String?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var isRefreshing = false

    var changes: [GitChange] {
        let all = (status?.changes ?? []).sorted { $0.area < $1.area }
        guard !filter.isEmpty else { return all }
        return all.filter { $0.path.localizedCaseInsensitiveContains(filter) }
    }

    var rows: [ChangesRow] {
        let changes = changes
        return GitChange.Area.allCases.flatMap { area -> [ChangesRow] in
            let inArea = changes.filter { $0.area == area }
            guard !inArea.isEmpty else { return [] }
            return [.section(area, count: inArea.count)] + inArea.map(ChangesRow.change)
        }
    }

    var selectedChange: GitChange? {
        guard let selection else { return nil }
        return status?.changes.first { $0.id == selection }
    }

    func change(at url: URL) -> GitChange? {
        guard let repository, let changes = status?.changes else { return nil }
        let root = repository.path(percentEncoded: false)
        let path = url.standardizedFileURL.path(percentEncoded: false)
        guard path.hasPrefix(root) else { return nil }
        let relative = String(path.dropFirst(root.count)).trimmingPrefix("/")
        let areas: [GitChange.Area] = [.unstaged, .staged, .untracked]
        return areas.lazy.compactMap { area in changes.first { $0.area == area && $0.path == relative } }.first
    }

    func follow(_ directory: String?) {
        guard let directory, directory != followedDirectory else { return }
        followedDirectory = directory
        generation += 1
        let current = generation
        if repository == nil { state = .loading }
        Task {
            let lookup = await GitClient.lookup(URL(filePath: directory, directoryHint: .isDirectory))
            guard current == generation else { return }
            switch lookup {
            case .repository(let root):
                if root != repository {
                    repository = root
                    status = nil
                    decorations = GitDecorations()
                    selection = nil
                    filter = ""
                    state = .loading
                }
                await refresh()
            case .notRepository:
                reset(to: .notRepository)
            case .gitMissing:
                reset(to: .gitMissing)
            }
        }
    }

    func refresh() async {
        guard let repository, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        guard let result = await GitClient.status(of: repository), repository == self.repository else { return }
        if result != status {
            status = result
            decorations = GitDecorations(status: result, repository: repository)
        }
        state = .ready
        if let selection, !result.changes.contains(where: { $0.id == selection }) {
            let path = selection.split(separator: ":", maxSplits: 1).last.map(String.init)
            self.selection = result.changes.first { $0.path == path }?.id
        }
    }

    func moveSelection(by offset: Int) {
        let changes = changes
        guard !changes.isEmpty else { return }
        let index = changes.firstIndex { $0.id == selection }.map { $0 + offset } ?? (offset > 0 ? 0 : changes.count - 1)
        selection = changes[min(max(index, 0), changes.count - 1)].id
    }

    private func reset(to state: State) {
        repository = nil
        status = nil
        decorations = GitDecorations()
        selection = nil
        self.state = state
    }
}
