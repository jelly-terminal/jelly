import AppKit
import JellyCore
import Observation
import SwiftUI

@Observable
final class ViewerModel {
    private(set) var url: URL
    private(set) var content: ViewerContent = .loading
    private(set) var history: [URL] = []
    var pendingAnchor: String?

    @ObservationIgnored let codeFont: NSFont
    @ObservationIgnored private var watcher: FileWatcher?
    @ObservationIgnored private var generation = 0

    init(url: URL, codeFont: NSFont) {
        self.url = url
        self.codeFont = codeFont
        show(url)
    }

    var title: String { url.lastPathComponent }

    var outline: [MarkdownDocument.Heading] {
        guard case .markdown(let document) = content else { return [] }
        return document.outline
    }

    func open(_ target: URL, anchor: String? = nil) {
        let target = target.standardizedFileURL
        if target != url {
            history.append(url)
            show(target)
        }
        pendingAnchor = anchor
    }

    func back() {
        guard let previous = history.popLast() else { return }
        show(previous)
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
        content = .loading
        watcher = FileWatcher(path: target.path(percentEncoded: false)) { [weak self] in self?.reload() }
        reload()
    }

    private func reload() {
        generation += 1
        let current = generation
        let target = url
        Task {
            let loaded = await ViewerLoader.load(target)
            guard current == generation else { return }
            content = loaded
        }
    }
}
