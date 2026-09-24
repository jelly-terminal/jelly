import AppKit
import JellyCore
import JellyTerminal
import Observation
import SwiftUI

@Observable
final class WindowModel {
    private(set) var sessions: [SessionModel]
    var selectedSessionID: UUID
    var isSidebarVisible: Bool
    var renamingSessionID: UUID?
    var pendingImport: PendingImport?
    var importError: String?
    var isExplorerVisible = false
    var explorerFocusRequest = 0
    var viewer: ViewerModel?
    var palette: PaletteModel?

    @ObservationIgnored let configStore: ConfigStore
    @ObservationIgnored let explorer = ExplorerModel()
    @ObservationIgnored weak var window: NSWindow?

    init(configStore: ConfigStore, snapshot: WorkspaceSnapshot.Window?) {
        self.configStore = configStore
        let restored = (snapshot?.sessions ?? []).map {
            SessionModel(id: $0.id, name: $0.name, configStore: configStore, tabs: $0.tabs, selectedTab: $0.selectedTab)
        }
        let initial = restored.isEmpty ? [SessionModel(name: "Default", configStore: configStore)] : restored
        let preferred = snapshot?.selectedSession
        sessions = initial
        selectedSessionID = initial.first { $0.id == preferred }?.id ?? initial[0].id
        isSidebarVisible = snapshot?.sidebarVisible ?? configStore.settings.window.sidebar
        selectedSession.activate()
    }

    var selectedSession: SessionModel {
        sessions.first { $0.id == selectedSessionID } ?? sessions[0]
    }

    var workspace: WorkspaceModel {
        selectedSession.workspace
    }

    var actions: ActionHandler {
        ActionHandler(window: self)
    }

    var snapshot: WorkspaceSnapshot.Window {
        WorkspaceSnapshot.Window(
            sessions: sessions.map(\.snapshot),
            selectedSession: selectedSessionID,
            sidebarVisible: isSidebarVisible,
            frame: window?.frameDescriptor
        )
    }

    var hasForegroundProcesses: Bool {
        sessions.contains { $0.workspace.hasForegroundProcesses }
    }

    func select(_ session: SessionModel) {
        session.activate()
        selectedSessionID = session.id
        focusTerminal()
    }

    func focusTerminal() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let surface = self.workspace.selectedTab?.surface else { return }
            self.window?.makeFirstResponder(surface)
        }
    }

    func selectSession(offset: Int) {
        guard let index = sessions.firstIndex(where: { $0.id == selectedSessionID }) else { return }
        select(sessions[(index + offset + sessions.count) % sessions.count])
    }

    func selectSession(number: Int) {
        guard !sessions.isEmpty else { return }
        select(number >= 9 ? sessions[sessions.count - 1] : sessions[min(number - 1, sessions.count - 1)])
    }

    func newSession() {
        let session = SessionModel(name: nextSessionName(), configStore: configStore)
        sessions.append(session)
        select(session)
    }

    func rename(_ session: SessionModel, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { session.name = trimmed }
        renamingSessionID = nil
        focusTerminal()
    }

    func cancelRename() {
        renamingSessionID = nil
        focusTerminal()
    }

    func requestDelete(_ session: SessionModel) {
        guard sessions.count > 1 else { return }
        guard session.workspace.hasForegroundProcesses, let window else {
            delete(session)
            return
        }
        let alert = NSAlert()
        alert.messageText = "Delete “\(session.name)”?"
        alert.informativeText = "Processes are still running in this session."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self, weak session] response in
            guard response == .alertFirstButtonReturn, let session else { return }
            self?.delete(session)
        }
    }

    func moveSessions(from source: IndexSet, to destination: Int) {
        sessions.move(fromOffsets: source, toOffset: destination)
    }

    func toggleExplorer() {
        withAnimation(Sidebar.animation) { isExplorerVisible.toggle() }
        if isExplorerVisible {
            syncExplorer()
            explorerFocusRequest += 1
        } else if viewer == nil {
            focusTerminal()
        }
    }

    func syncExplorer() {
        explorer.follow(workspace.selectedTab?.surface.workingDirectory)
    }

    func preview(_ url: URL) {
        if let viewer {
            viewer.open(url)
        } else {
            let codeFont = FontResolver.resolve(configStore.settings.font, size: Metrics.markdownCodeSize).font
            viewer = ViewerModel(url: url, codeFont: codeFont)
        }
    }

    func closeViewer() {
        viewer = nil
        if isExplorerVisible {
            explorerFocusRequest += 1
        } else {
            focusTerminal()
        }
    }

    func togglePreview() {
        if viewer != nil {
            closeViewer()
            return
        }
        if isExplorerVisible, let entry = explorer.selectedEntry, !entry.isDirectory {
            preview(entry.url)
            return
        }
        guard let directory = workspace.selectedTab?.surface.workingDirectory else {
            NSSound.beep()
            return
        }
        Task {
            guard let readme = await DirectoryLister.readme(in: URL(filePath: directory, directoryHint: .isDirectory)) else {
                NSSound.beep()
                return
            }
            preview(readme)
        }
    }

    func togglePalette() {
        if palette != nil {
            closePalette()
        } else {
            palette = PaletteModel(window: self, sources: PaletteSources.all) { [weak self] item, revertPreview in
                self?.closePalette()
                DispatchQueue.main.async {
                    item.perform()
                    revertPreview?()
                }
            }
        }
    }

    func closePalette() {
        guard let palette else { return }
        palette.cancelPreview()
        self.palette = nil
        if viewer == nil { focusTerminal() }
    }

    func handlePaletteKey(_ event: NSEvent) -> Bool {
        guard let palette else { return false }
        if event.charactersIgnoringModifiers == "\u{1B}" {
            closePalette()
            return true
        }
        return palette.handle(event)
    }

    func terminateAll() {
        sessions.forEach { $0.workspace.terminateAll() }
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

    private func delete(_ session: SessionModel) {
        guard let index = sessions.firstIndex(where: { $0 === session }), sessions.count > 1 else { return }
        session.workspace.terminateAll()
        sessions.remove(at: index)
        if selectedSessionID == session.id {
            select(sessions[min(index, sessions.count - 1)])
        }
    }

    private func nextSessionName() -> String {
        let names = Set(sessions.map(\.name))
        var number = sessions.count + 1
        while names.contains("Session \(number)") { number += 1 }
        return "Session \(number)"
    }
}
