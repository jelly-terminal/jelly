import Foundation
import Observation

@Observable
final class ExplorerModel {
    private(set) var root: URL?
    private(set) var children: [URL: [ExplorerEntry]] = [:]
    private(set) var expanded: Set<URL> = []
    var selection: URL?
    var filter = ""
    var showHidden = false {
        didSet { reloadAll() }
    }

    @ObservationIgnored private var followedDirectory: String?
    @ObservationIgnored private var watchers: [URL: FileWatcher] = [:]

    var rows: [ExplorerRow] {
        guard let root else { return [] }
        var rows: [ExplorerRow] = []
        appendRows(of: root, depth: 0, into: &rows)
        guard !filter.isEmpty else { return rows }
        return rows.filter { $0.entry.name.localizedCaseInsensitiveContains(filter) }
    }

    var selectedEntry: ExplorerEntry? {
        guard let selection else { return nil }
        return rows.first { $0.entry.url == selection }?.entry
    }

    func follow(_ directory: String?) {
        guard let directory, directory != followedDirectory else { return }
        followedDirectory = directory
        setRoot(URL(filePath: directory, directoryHint: .isDirectory))
    }

    func setRoot(_ url: URL) {
        let url = url.standardizedFileURL
        guard url != root else { return }
        let previous = root
        root = url
        children = [:]
        expanded = []
        watchers = [:]
        filter = ""
        selection = previous?.deletingLastPathComponent().standardizedFileURL == url ? previous?.standardizedFileURL : nil
        load(url)
    }

    func goUp() {
        guard let root, root.path != "/" else { return }
        setRoot(root.deletingLastPathComponent())
    }

    func toggle(_ entry: ExplorerEntry) {
        guard entry.isDirectory else { return }
        expanded.contains(entry.url) ? collapse(entry.url) : expand(entry.url)
    }

    func expand(_ url: URL) {
        guard !expanded.contains(url) else { return }
        expanded.insert(url)
        if children[url] == nil { load(url) } else { watch(url) }
    }

    func collapse(_ url: URL) {
        expanded.remove(url)
        watchers[url] = nil
        if let selection, selection.path.hasPrefix(url.path + "/") { self.selection = url }
    }

    func moveSelection(by offset: Int) {
        let rows = rows
        guard !rows.isEmpty else { return }
        let index = rows.firstIndex { $0.entry.url == selection }.map { $0 + offset } ?? (offset > 0 ? 0 : rows.count - 1)
        selection = rows[min(max(index, 0), rows.count - 1)].entry.url
    }

    func expandSelection() {
        guard let entry = selectedEntry, entry.isDirectory else { return }
        if expanded.contains(entry.url) {
            if let first = children[entry.url]?.first { selection = first.url }
        } else {
            expand(entry.url)
        }
    }

    func collapseSelection() {
        guard let entry = selectedEntry else { return }
        if entry.isDirectory, expanded.contains(entry.url) {
            collapse(entry.url)
        } else {
            let parent = entry.url.deletingLastPathComponent().standardizedFileURL
            if parent != root { selection = parent }
        }
    }

    func stop() {
        watchers = [:]
    }

    func resume() {
        guard let root else { return }
        load(root)
        expanded.forEach(load)
    }

    private func appendRows(of directory: URL, depth: Int, into rows: inout [ExplorerRow]) {
        for entry in children[directory] ?? [] {
            let isExpanded = expanded.contains(entry.url)
            rows.append(ExplorerRow(entry: entry, depth: depth, isExpanded: isExpanded))
            if isExpanded { appendRows(of: entry.url, depth: depth + 1, into: &rows) }
        }
    }

    private func reloadAll() {
        guard let root else { return }
        children = [:]
        load(root)
        expanded.forEach(load)
    }

    private func load(_ directory: URL) {
        reload(directory)
        watch(directory)
    }

    private func reload(_ directory: URL) {
        let showHidden = showHidden
        Task {
            let entries = await DirectoryLister.list(directory, showHidden: showHidden)
            guard directory == root || expanded.contains(directory), showHidden == self.showHidden else { return }
            if children[directory] != entries { children[directory] = entries }
        }
    }

    private func watch(_ directory: URL) {
        guard watchers[directory] == nil else { return }
        watchers[directory] = FileWatcher(path: directory.path(percentEncoded: false)) { [weak self] in
            self?.reload(directory)
        }
    }
}
