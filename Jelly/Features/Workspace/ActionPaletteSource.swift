import AppKit
import JellyCore

struct ActionPaletteSource: PaletteSource {
    let section = "Actions"

    func items(in window: WindowModel) -> [PaletteItem] {
        let keybinds = window.configStore.config.keybinds
        return KeyAction.catalog.filter(Self.isListed).map { action in
            PaletteItem(
                id: "action:" + action.name,
                title: action.title,
                subtitle: action.group.rawValue,
                symbol: Self.symbol(for: action.group),
                shortcut: keybinds.chord(for: action),
                keywords: [action.group.rawValue + " " + action.title, action.name]
            ) {
                if action == .settingsOpen {
                    (NSApp.delegate as? AppDelegate)?.showSettings()
                } else {
                    _ = window.actions.perform(action)
                }
            }
        }
    }

    private static func isListed(_ action: KeyAction) -> Bool {
        switch action {
        case .tabGoto, .sessionGoto, .copy, .paste, .tabRename, .promptPrevious, .promptNext, .paletteToggle, .text, .none:
            false
        default:
            true
        }
    }

    private static func symbol(for group: KeyAction.Group) -> String {
        switch group {
        case .tabs: "square.on.square"
        case .panes: "rectangle.split.2x1"
        case .sessions: "rectangle.stack"
        case .window: "macwindow"
        case .edit: "character.cursor.ibeam"
        case .font: "textformat.size"
        case .agents: "sparkle"
        case .config: "gearshape"
        }
    }
}
