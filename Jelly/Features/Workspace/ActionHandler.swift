import AppKit
import JellyCore
import JellyTerminal

@MainActor
struct ActionHandler {
    let workspace: WorkspaceModel
    let configStore: ConfigStore
    let window: NSWindow?

    func perform(_ action: KeyAction) -> Bool {
        let surface = workspace.selectedTab?.surface
        switch action {
        case .tabNew:
            workspace.newTab()
        case .tabClose, .paneClose:
            guard let tab = workspace.selectedTab else { return false }
            workspace.requestClose(tab, in: window)
        case .tabNext:
            workspace.select(offset: 1)
        case .tabPrevious:
            workspace.select(offset: -1)
        case .tabGoto(let number):
            workspace.select(number: number)
        case .find:
            surface?.showFind()
        case .clear:
            surface?.clearScreen()
        case .copy:
            guard let surface else { return false }
            surface.copySelection()
        case .paste:
            guard let surface else { return false }
            surface.pasteClipboard()
        case .fontIncrease:
            configStore.fontSizeDelta += 1
        case .fontDecrease:
            configStore.fontSizeDelta -= 1
        case .fontReset:
            configStore.fontSizeDelta = 0
        case .configOpen:
            configStore.openConfigFile()
        case .configReload:
            configStore.reload()
        case .text(let text):
            surface?.sendText(text)
        case .tabRename, .splitRight, .splitDown, .paneZoom, .paneFocus, .paneEqualize,
             .sessionNew, .sessionNext, .sessionPrevious, .sidebarToggle, .promptPrevious, .promptNext, .none:
            return false
        }
        return true
    }
}
