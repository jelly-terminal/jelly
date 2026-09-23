import Foundation

enum DirectoryLister {
    @concurrent
    nonisolated static func list(_ directory: URL, showHidden: Bool) async -> [ExplorerEntry] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: options)) ?? []
        let entries = urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let isDirectory = values?.isDirectory == true && values?.isPackage != true
            return ExplorerEntry(url: url, name: url.lastPathComponent, isDirectory: isDirectory)
        }
        return entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    @concurrent
    nonisolated static func readme(in directory: URL) async -> URL? {
        let entries = await list(directory, showHidden: false).filter { !$0.isDirectory && $0.isMarkdown }
        let preferred = entries.first { $0.url.deletingPathExtension().lastPathComponent.lowercased() == "readme" }
        return (preferred ?? entries.first)?.url
    }
}
