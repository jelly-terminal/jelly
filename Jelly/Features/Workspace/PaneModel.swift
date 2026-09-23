import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class PaneModel: Identifiable {
    let surface: TerminalSurface
    private(set) var title = ""
    private(set) var directory: String?
    private(set) var gridSize = (cols: 0, rows: 0)

    init(surface: TerminalSurface) {
        self.surface = surface
        gridSize = surface.gridSize
        surface.onTitleChange = { [weak self] in self?.title = $0 }
        surface.onDirectoryChange = { [weak self] in self?.directory = $0 }
        surface.onGridSizeChange = { [weak self] cols, rows in self?.gridSize = (cols, rows) }
    }

    var id: PaneID { surface.paneID }

    var displayTitle: String {
        if !title.isEmpty { return title }
        if let directory { return (directory as NSString).lastPathComponent }
        return "shell"
    }
}
