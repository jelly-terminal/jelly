import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class TabModel: Identifiable {
    let id = UUID()
    let surface: TerminalSurface
    var customTitle: String?
    private(set) var title = ""
    private(set) var directory: String?
    private(set) var gridSize = (cols: 0, rows: 0)

    init(surface: TerminalSurface) {
        self.surface = surface
        surface.onTitleChange = { [weak self] in self?.title = $0 }
        surface.onDirectoryChange = { [weak self] in self?.directory = $0 }
        surface.onGridSizeChange = { [weak self] cols, rows in self?.gridSize = (cols, rows) }
    }

    var displayTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        if !title.isEmpty { return title }
        if let directory { return (directory as NSString).lastPathComponent }
        return "shell"
    }
}
