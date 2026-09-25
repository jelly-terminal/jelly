import AppKit
import JellyCore
import JellyTerminal
import SwiftUI

@MainActor
struct ActionHandler {
    let window: WindowModel

    func perform(_ action: KeyAction) -> Bool {
        let workspace = window.workspace
        let configStore = window.configStore
        let surface = workspace.selectedTab?.surface
        if window.palette != nil, action != .paletteToggle {
            switch action {
            case .copy, .paste, .text: return false
            default: window.closePalette()
            }
        }
        switch action {
        case .tabNew:
            withAnimation(TabBar.animation) { _ = workspace.newTab() }
        case .tabClose:
            guard let tab = workspace.selectedTab else { return false }
            withAnimation(TabBar.animation) { workspace.requestClose(tab, in: window.window) }
        case .paneClose:
            guard let tab = workspace.selectedTab else { return false }
            withAnimation(TabBar.animation) { workspace.requestClose(tab.focusedPane, in: tab, window: window.window) }
        case .splitRight:
            workspace.split(.horizontal)
        case .splitDown:
            workspace.split(.vertical)
        case .paneZoom:
            workspace.selectedTab?.toggleZoom()
        case .paneFocus(let direction):
            workspace.selectedTab?.focus(toward: direction)
        case .paneEqualize:
            workspace.selectedTab?.equalize()
        case .tabMove(let direction):
            withAnimation(TabBar.animation) { workspace.moveSelected(by: direction == .left ? -1 : 1) }
        case .tabNext:
            workspace.select(offset: 1)
        case .tabPrevious:
            workspace.select(offset: -1)
        case .tabGoto(let number):
            workspace.select(number: number)
        case .sessionNew:
            withAnimation(TabBar.animation) { window.newSession() }
        case .sessionNext:
            window.switchSession(by: 1)
        case .sessionPrevious:
            window.switchSession(by: -1)
        case .sessionGoto(let number):
            window.selectSession(number: number)
        case .sidebarToggle:
            withAnimation(Sidebar.animation) { window.isSidebarVisible.toggle() }
        case .explorerToggle:
            window.toggleExplorer()
        case .markdownPreview:
            window.togglePreview()
        case .activityToggle:
            window.toggleActivity()
        case .paletteToggle:
            window.togglePalette()
        case .find:
            surface?.showFind()
        case .clear:
            surface?.clearScreen()
        case .copy:
            guard let surface, window.window?.firstResponder === surface else { return false }
            surface.copySelection()
        case .paste:
            guard let surface, window.window?.firstResponder === surface else { return false }
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
        case .agentNextWaiting:
            window.revealNextWaitingAgent()
        case .text(let text):
            surface?.sendText(text)
        case .tabRename, .settingsOpen, .promptPrevious, .promptNext, .none:
            return false
        }
        return true
    }
}
