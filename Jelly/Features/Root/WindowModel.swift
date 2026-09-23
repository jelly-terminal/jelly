import AppKit
import JellyCore
import JellyTerminal
import Observation

@Observable
final class WindowModel {
    let workspace: WorkspaceModel
    var pendingImport: PendingImport?
    var importError: String?

    @ObservationIgnored let configStore: ConfigStore
    @ObservationIgnored weak var window: NSWindow?

    init(configStore: ConfigStore) {
        self.configStore = configStore
        workspace = WorkspaceModel(configStore: configStore)
    }

    var actions: ActionHandler {
        ActionHandler(workspace: workspace, configStore: configStore, window: window)
    }

    func handleDrop(_ urls: [URL]) {
        let files = urls.filter(\.isFileURL)
        guard !files.isEmpty else { return }
        if let toml = files.first(where: { $0.pathExtension.lowercased() == "toml" }) {
            beginImport(toml)
        } else {
            workspace.selectedTab?.surface.insertPaths(files)
        }
    }

    func beginImport(_ url: URL) {
        do {
            pendingImport = try PendingImport(url: url, configStore: configStore)
        } catch {
            importError = "Couldn’t read \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func confirmImport(_ pending: PendingImport) {
        pendingImport = nil
        do {
            try ConfigImportService.apply(pending, to: configStore)
        } catch {
            importError = "Import failed: \(error)"
        }
    }

    func insertPendingPath() {
        guard let pending = pendingImport else { return }
        pendingImport = nil
        workspace.selectedTab?.surface.insertPaths([pending.url])
    }
}
