import AppKit
import JellyCore
import Observation
import SwiftUI

@Observable
final class ViewerModel {
    struct HunkMove: Equatable {
        let offset: Int
        let serial: Int
    }

    private(set) var url: URL
    private(set) var diff: DiffTarget?
    private(set) var content: ViewerContent = .loading
    private(set) var history: [URL] = []
    private(set) var hunkMove = HunkMove(offset: 0, serial: 0)
    var pendingAnchor: String?

    @ObservationIgnored let codeFont: NSFont
    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var indexWatcher: FileWatcher?
    @ObservationIgnored private var generation = 0

    init(url: URL, codeFont: NSFont) {
        self.url = url
        self.codeFont = codeFont
        show(url)
    }

    init(diff: DiffTarget, codeFont: NSFont) {
        self.url = diff.url
        self.codeFont = codeFont
        show(diff)
    }

    var title: String { url.lastPathComponent }

    var outline: [MarkdownDocument.Heading] {
        guard case .markdown(let document) = content else { return [] }
        return document.outline
    }

    func open(_ target: URL, anchor: String? = nil) {
        let target = target.standardizedFileURL
        if target != url || diff != nil {
            if diff == nil { history.append(url) }
            show(target)
        }
        pendingAnchor = anchor
    }

    func open(_ target: DiffTarget) {
        history = []
        guard target != diff else { return }
        show(target)
    }

    func back() {
        guard let previous = history.popLast() else { return }
        show(previous)
    }

    func moveHunk(by offset: Int) {
        hunkMove = HunkMove(offset: offset, serial: hunkMove.serial + 1)
    }

    func handle(_ link: URL) -> OpenURLAction.Result {
        if let scheme = link.scheme, scheme != "file" { return .systemAction }
        let fragment = link.fragment(percentEncoded: false)
        if link.path(percentEncoded: false).isEmpty {
            pendingAnchor = fragment
            return .handled
        }
        let base = url.deletingLastPathComponent()
        let target = link.isFileURL ? link : URL(filePath: link.path(percentEncoded: false), relativeTo: base).absoluteURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path(percentEncoded: false), isDirectory: &isDirectory), !isDirectory.boolValue else {
            return .systemAction(target)
        }
        open(target, anchor: fragment)
        return .handled
    }

    private func show(_ target: URL) {
        url = target
        diff = nil
        content = .loading
        indexWatcher = nil
        watcher = FileWatcher(path: target.path(percentEncoded: false)) { [weak self] in self?.reload() }
        reload()
    }

    private func show(_ target: DiffTarget) {
        url = target.url
        diff = target
        content = .loading
        watcher = FileWatcher(path: target.url.path(percentEncoded: false)) { [weak self] in self?.reload() }
        let index = target.repository.appending(path: ".git/index").path(percentEncoded: false)
        indexWatcher = FileWatcher(path: index) { [weak self] in self?.reload() }
        reload()
    }

    private func reload() {
        generation += 1
        let current = generation
        let target = url
        let diff = diff
        Task {
            let loaded = if let diff { await DiffLoader.load(diff) } else { await ViewerLoader.load(target) }
            guard current == generation else { return }
            content = loaded
        }
    }
}
