import AppKit
import JellyCore

final class KeyActionBox {
    let action: KeyAction

    init(_ action: KeyAction) {
        self.action = action
    }
}

enum MainMenu {
    static func build(target: AppDelegate, keybinds: Keybinds, updatesAvailable: Bool) -> NSMenu {
        func item(_ title: String, _ action: KeyAction) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: #selector(AppDelegate.performMenuAction(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = KeyActionBox(action)
            if let chord = keybinds.chord(for: action) {
                let equivalent = chord.keyEquivalent
                item.keyEquivalent = equivalent.key
                item.keyEquivalentModifierMask = equivalent.modifiers
            }
            return item
        }

        let main = NSMenu()
        main.addItem(submenu(appMenu(target: target, item: item, updatesAvailable: updatesAvailable)))
        main.addItem(submenu(fileMenu(target: target, item: item)))
        main.addItem(submenu(editMenu(item: item)))
        main.addItem(submenu(viewMenu(item: item)))
        let window = windowMenu(item: item)
        main.addItem(submenu(window))
        NSApp.windowsMenu = window
        return main
    }

    private static func submenu(_ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem()
        item.submenu = menu
        return item
    }

    private static func appMenu(target: AppDelegate, item: (String, KeyAction) -> NSMenuItem, updatesAvailable: Bool) -> NSMenu {
        let name = AppInfo.name
        let menu = NSMenu(title: name)
        menu.addItem(withTitle: "About \(name)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        let updates = menu.addItem(withTitle: "Check for Updates…", action: #selector(AppDelegate.checkForUpdates), keyEquivalent: "")
        updates.target = target
        updates.isEnabled = updatesAvailable
        menu.addItem(.separator())
        menu.addItem(item("Settings…", .settingsOpen))
        menu.addItem(item("Open Config File…", .configOpen))
        menu.addItem(item("Reload Config", .configReload))
        menu.addItem(.separator())
        let services = NSMenu(title: "Services")
        menu.addItem(withTitle: "Services", action: nil, keyEquivalent: "").submenu = services
        NSApp.servicesMenu = services
        menu.addItem(.separator())
        menu.addItem(withTitle: "Hide \(name)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            .keyEquivalentModifierMask = [.command, .option]
        menu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit \(name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private static func fileMenu(target: AppDelegate, item: (String, KeyAction) -> NSMenuItem) -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.addItem(item("New Tab", .tabNew))
        menu.addItem(withTitle: "New Window", action: #selector(AppDelegate.newWindow), keyEquivalent: "n").target = target
        menu.addItem(.separator())
        let importItem = menu.addItem(withTitle: "Import…", action: #selector(AppDelegate.importConfig), keyEquivalent: "i")
        importItem.keyEquivalentModifierMask = [.command, .shift]
        importItem.target = target
        menu.addItem(.separator())
        menu.addItem(item("Split Right", .splitRight))
        menu.addItem(item("Split Down", .splitDown))
        menu.addItem(.separator())
        menu.addItem(item("Close Pane", .paneClose))
        menu.addItem(item("Close Tab", .tabClose))
        menu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "W")
        return menu
    }

    private static func editMenu(item: (String, KeyAction) -> NSMenuItem) -> NSMenu {
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(item("Copy", .copy))
        menu.addItem(item("Paste", .paste))
        menu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(.separator())
        menu.addItem(item("Find…", .find))
        menu.addItem(item("Clear", .clear))
        return menu
    }

    private static func viewMenu(item: (String, KeyAction) -> NSMenuItem) -> NSMenu {
        let menu = NSMenu(title: "View")
        menu.addItem(item("Bigger", .fontIncrease))
        menu.addItem(item("Smaller", .fontDecrease))
        menu.addItem(item("Actual Size", .fontReset))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
            .keyEquivalentModifierMask = [.command, .control]
        return menu
    }

    private static func windowMenu(item: (String, KeyAction) -> NSMenuItem) -> NSMenu {
        let menu = NSMenu(title: "Window")
        menu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        menu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(item("Show Next Tab", .tabNext))
        menu.addItem(item("Show Previous Tab", .tabPrevious))
        menu.addItem(item("Move Tab Left", .tabMove(.left)))
        menu.addItem(item("Move Tab Right", .tabMove(.right)))
        menu.addItem(.separator())
        menu.addItem(item("Select Pane Left", .paneFocus(.left)))
        menu.addItem(item("Select Pane Right", .paneFocus(.right)))
        menu.addItem(item("Select Pane Above", .paneFocus(.up)))
        menu.addItem(item("Select Pane Below", .paneFocus(.down)))
        menu.addItem(item("Zoom Pane", .paneZoom))
        menu.addItem(item("Equalize Panes", .paneEqualize))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        return menu
    }
}
