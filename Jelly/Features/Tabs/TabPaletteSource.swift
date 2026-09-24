import Foundation
import JellyCore
import JellyTerminal

struct TabPaletteSource: PaletteSource {
    let section = "Tabs"

    func items(in window: WindowModel) -> [PaletteItem] {
        let workspace = window.workspace
        return workspace.tabs.map { tab in
            PaletteItem(
                id: "tab:" + tab.id.uuidString,
                title: tab.displayTitle,
                subtitle: tab.surface.workingDirectory.map { ($0 as NSString).abbreviatingWithTildeInPath },
                symbol: "terminal",
                keywords: ["Tab " + tab.displayTitle],
                isCurrent: tab.id == workspace.selectedID
            ) {
                workspace.selectedID = tab.id
                window.focusTerminal()
            }
        }
    }
}
