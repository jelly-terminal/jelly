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
        switch action {
        case .tabNew:
            withAnimation(TabBar.animation) { _ = workspace.newTab() }
        case .tabClose, .paneClose:
            guard let tab = workspace.selectedTab else { return false }
            withAnimation(TabBar.animation) { workspace.requestClose(tab, in: window.window) }
        case .tabNext:
            workspace.select(offset: 1)
        case .tabPrevious:
            workspace.select(offset: -1)
        case .tabGoto(let number):
            workspace.select(number: number)
        case .sessionNew:
            withAnimation(TabBar.animation) { window.newSession() }
        case .sessionNext:
            window.selectSession(offset: 1)
        case .sessionPrevious:
            window.selectSession(offset: -1)
        case .sidebarToggle:
            withAnimation(Sidebar.animation) { window.isSidebarVisible.toggle() }
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
             .promptPrevious, .promptNext, .none:
            return false
        }
        return true
    }
}
