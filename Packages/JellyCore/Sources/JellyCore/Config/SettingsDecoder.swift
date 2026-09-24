enum SettingsDecoder {
    static func decode(_ table: TOMLTable) -> (Settings, [Diagnostic]) {
        var settings = Settings()
        var reader = TableReader(table, path: "settings")

        if let value = reader.raw("theme") {
            switch value {
            case .string(let id):
                settings.theme = .fixed(id)
            case .table(let pair):
                if case .string(let light)? = pair["light"], case .string(let dark)? = pair["dark"] {
                    settings.theme = .adaptive(light: light, dark: dark)
                } else {
                    reader.report("theme", "expected { light = \"…\", dark = \"…\" }")
                }
            default:
                reader.report("theme", "expected a theme id or { light, dark }")
            }
        }
        settings.scrollback = reader.int("scrollback", in: 0...1_000_000) ?? settings.scrollback
        settings.confirmQuit = reader.bool("confirm-quit") ?? settings.confirmQuit

        if var font = reader.table("font") {
            decodeFont(&font, into: &settings.font)
            reader.merge(font)
        }
        if var window = reader.table("window") {
            decodeWindow(&window, into: &settings.window)
            reader.merge(window)
        }
        if var cursor = reader.table("cursor") {
            settings.cursor.style = cursor.choice("style", ["block": .block, "bar": .bar, "underline": .underline]) ?? settings.cursor.style
            settings.cursor.blink = cursor.bool("blink") ?? settings.cursor.blink
            reader.merge(cursor)
        }
        if var shell = reader.table("shell") {
            decodeShell(&shell, into: &settings.shell)
            reader.merge(shell)
        }
        if var clipboard = reader.table("clipboard") {
            settings.clipboard.copyOnSelect = clipboard.bool("copy-on-select") ?? settings.clipboard.copyOnSelect
            settings.clipboard.osc52Read = clipboard.bool("osc52-read") ?? settings.clipboard.osc52Read
            reader.merge(clipboard)
        }
        if var updates = reader.table("updates") {
            settings.updates.check = updates.bool("check") ?? settings.updates.check
            settings.updates.autoInstall = updates.bool("auto-install") ?? settings.updates.autoInstall
            reader.merge(updates)
        }
        if var session = reader.table("session") {
            settings.session.keepAlive = session.bool("keep-alive") ?? settings.session.keepAlive
            reader.merge(session)
        }
        if var telemetry = reader.table("telemetry") {
            settings.telemetry.enabled = telemetry.bool("enabled") ?? settings.telemetry.enabled
            reader.merge(telemetry)
        }
        if var agents = reader.table("agents") {
            decodeAgents(&agents, into: &settings.agents)
            reader.merge(agents)
        }
        return (settings, reader.finished())
    }

    private static func decodeFont(_ reader: inout TableReader, into font: inout FontSettings) {
        font.family = reader.string("family") ?? font.family
        font.size = reader.double("size", in: 4...200) ?? font.size
        font.fallback = reader.strings("fallback") ?? font.fallback
        font.ligatures = reader.bool("ligatures") ?? font.ligatures
        font.features = reader.strings("features") ?? font.features
        font.thicken = reader.bool("thicken") ?? font.thicken
        for (key, keyPath) in [("cell-width", \FontSettings.cellWidth), ("cell-height", \FontSettings.cellHeight)] {
            guard let raw = reader.string(key) else { continue }
            if let adjustment = CellAdjustment(raw) {
                font[keyPath: keyPath] = adjustment
            } else {
                reader.report(key, "expected a percentage like \"110%\" or points like \"+2\"")
            }
        }
    }

    private static func decodeWindow(_ reader: inout TableReader, into window: inout WindowSettings) {
        window.backgroundOpacity = reader.double("background-opacity", in: 0...1) ?? window.backgroundOpacity
        window.blur = reader.int("blur", in: 0...100) ?? window.blur
        window.sidebar = reader.bool("sidebar") ?? window.sidebar
        window.statusBar = reader.bool("status-bar") ?? window.statusBar
        window.tabStyle = reader.choice("tab-style", Dictionary(uniqueKeysWithValues: WindowSettings.TabStyle.allCases.map { ($0.rawValue, $0) })) ?? window.tabStyle
        if var padding = reader.table("padding") {
            window.paddingX = padding.double("x", in: 0...200) ?? window.paddingX
            window.paddingY = padding.double("y", in: 0...200) ?? window.paddingY
            reader.merge(padding)
        }
    }

    private static func decodeAgents(_ reader: inout TableReader, into agents: inout AgentSettings) {
        agents.enabled = reader.bool("enabled") ?? agents.enabled
        agents.idleAfter = reader.int("idle-after", in: 1...3600) ?? agents.idleAfter
        agents.notify = reader.choice("notify", Dictionary(uniqueKeysWithValues: AgentSettings.Notify.allCases.map { ($0.rawValue, $0) })) ?? agents.notify
        agents.notifySound = reader.bool("notify-sound") ?? agents.notifySound
        agents.notifyFinished = reader.bool("notify-finished") ?? agents.notifyFinished
        if let watch = reader.strings("watch") {
            let known = Set(AgentCatalog.builtIn.map(\.id))
            for id in watch where !known.contains(id) {
                reader.report("watch", "unknown agent '\(id)', expected one of \(known.sorted().joined(separator: ", "))")
            }
            agents.watch = watch
        }
        guard let value = reader.raw("custom") else { return }
        guard case .array(let items) = value else {
            reader.report("custom", "expected a list like [{ name = \"My Agent\", commands = [\"my-agent\"] }]")
            return
        }
        for item in items {
            guard case .table(let table) = item,
                  case .string(let name)? = table["name"], !name.isEmpty,
                  case .array(let values)? = table["commands"]
            else {
                reader.report("custom", "each agent needs a name and a list of commands")
                continue
            }
            let commands = values.compactMap { value -> String? in
                if case .string(let command) = value, !command.isEmpty { return command }
                return nil
            }
            guard commands.count == values.count, !commands.isEmpty else {
                reader.report("custom", "\(name): commands must be a non-empty list of strings")
                continue
            }
            agents.custom.append(AgentSettings.Custom(name: name, commands: commands))
        }
    }

    private static func decodeShell(_ reader: inout TableReader, into shell: inout ShellSettings) {
        if let program = reader.string("program") {
            if program.hasPrefix("/") || program.hasPrefix("~") {
                shell.program = program
            } else {
                reader.report("program", "must be an absolute path")
            }
        }
        shell.args = reader.strings("args") ?? shell.args
        if let directory = reader.string("working-directory") {
            switch directory {
            case "inherit": shell.workingDirectory = .inherit
            case "home": shell.workingDirectory = .home
            default: shell.workingDirectory = .path(directory)
            }
        }
        if var env = reader.table("env") {
            for key in env.table.keys {
                if let value = env.string(key) { shell.env[key] = value }
            }
            reader.merge(env)
        }
    }
}
