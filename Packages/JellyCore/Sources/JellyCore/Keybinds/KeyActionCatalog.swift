extension KeyAction {
    public enum Group: String, CaseIterable, Sendable {
        case tabs = "Tabs"
        case panes = "Panes"
        case sessions = "Sessions"
        case window = "Window"
        case edit = "Edit"
        case font = "Font"
        case agents = "Agents"
        case config = "Settings"
    }

    public static let catalog: [KeyAction] = [
        .tabNew, .tabClose, .tabNext, .tabPrevious, .tabMove(.left), .tabMove(.right),
    ] + (1...9).map { .tabGoto($0) } + [
        .splitRight, .splitDown, .paneClose, .paneZoom, .paneEqualize,
        .paneFocus(.left), .paneFocus(.right), .paneFocus(.up), .paneFocus(.down),
        .sessionNew, .sessionNext, .sessionPrevious,
    ] + (1...9).map { .sessionGoto($0) } + [
        .paletteToggle, .sidebarToggle, .explorerToggle, .markdownPreview, .find,
        .copy, .paste, .clear, .promptPrevious, .promptNext,
        .fontIncrease, .fontDecrease, .fontReset,
        .agentNextWaiting,
        .settingsOpen, .configOpen, .configReload,
    ]

    public var name: String {
        switch self {
        case .tabNew: "tab.new"
        case .tabClose: "tab.close"
        case .tabNext: "tab.next"
        case .tabPrevious: "tab.previous"
        case .tabGoto(let number): "tab.goto:\(number)"
        case .tabMove(let direction): "tab.move:\(direction.rawValue)"
        case .tabRename: "tab.rename"
        case .splitRight: "split.right"
        case .splitDown: "split.down"
        case .paneClose: "pane.close"
        case .paneZoom: "pane.zoom"
        case .paneFocus(let direction): "pane.focus:\(direction.rawValue)"
        case .paneEqualize: "pane.equalize"
        case .sessionNew: "session.new"
        case .sessionNext: "session.next"
        case .sessionPrevious: "session.previous"
        case .sessionGoto(let number): "session.goto:\(number)"
        case .sidebarToggle: "sidebar.toggle"
        case .explorerToggle: "explorer.toggle"
        case .markdownPreview: "markdown.preview"
        case .paletteToggle: "palette.toggle"
        case .find: "find"
        case .clear: "clear"
        case .copy: "copy"
        case .paste: "paste"
        case .fontIncrease: "font.increase"
        case .fontDecrease: "font.decrease"
        case .fontReset: "font.reset"
        case .settingsOpen: "settings.open"
        case .configOpen: "config.open"
        case .configReload: "config.reload"
        case .promptPrevious: "prompt.previous"
        case .promptNext: "prompt.next"
        case .agentNextWaiting: "agent.next-waiting"
        case .text(let text): "text:" + Self.escape(text)
        case .none: "none"
        }
    }

    public var title: String {
        switch self {
        case .tabNew: "New Tab"
        case .tabClose: "Close Tab"
        case .tabNext: "Next Tab"
        case .tabPrevious: "Previous Tab"
        case .tabGoto(let number): number == 9 ? "Last Tab" : "Tab \(number)"
        case .tabMove(let direction): "Move Tab \(direction.rawValue.capitalized)"
        case .tabRename: "Rename Tab"
        case .splitRight: "Split Right"
        case .splitDown: "Split Down"
        case .paneClose: "Close Pane"
        case .paneZoom: "Zoom Pane"
        case .paneFocus(let direction):
            switch direction {
            case .left: "Select Pane Left"
            case .right: "Select Pane Right"
            case .up: "Select Pane Above"
            case .down: "Select Pane Below"
            }
        case .paneEqualize: "Equalize Panes"
        case .sessionNew: "New Session"
        case .sessionNext: "Next Session"
        case .sessionPrevious: "Previous Session"
        case .sessionGoto(let number): number == 9 ? "Last Session" : "Session \(number)"
        case .sidebarToggle: "Toggle Sidebar"
        case .explorerToggle: "Toggle Explorer"
        case .markdownPreview: "Preview Markdown"
        case .paletteToggle: "Command Palette"
        case .find: "Find"
        case .clear: "Clear"
        case .copy: "Copy"
        case .paste: "Paste"
        case .fontIncrease: "Bigger"
        case .fontDecrease: "Smaller"
        case .fontReset: "Actual Size"
        case .settingsOpen: "Settings"
        case .configOpen: "Open Config File"
        case .configReload: "Reload Config"
        case .promptPrevious: "Previous Prompt"
        case .promptNext: "Next Prompt"
        case .agentNextWaiting: "Jump to Waiting Agent"
        case .text: "Send Text"
        case .none: "None"
        }
    }

    public var group: Group {
        switch self {
        case .tabNew, .tabClose, .tabNext, .tabPrevious, .tabGoto, .tabMove, .tabRename: .tabs
        case .splitRight, .splitDown, .paneClose, .paneZoom, .paneFocus, .paneEqualize: .panes
        case .sessionNew, .sessionNext, .sessionPrevious, .sessionGoto: .sessions
        case .paletteToggle, .sidebarToggle, .explorerToggle, .markdownPreview, .find: .window
        case .clear, .copy, .paste, .promptPrevious, .promptNext, .text, .none: .edit
        case .fontIncrease, .fontDecrease, .fontReset: .font
        case .agentNextWaiting: .agents
        case .settingsOpen, .configOpen, .configReload: .config
        }
    }

    private static func escape(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            case "\u{1B}": result += "\\e"
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result
    }
}
