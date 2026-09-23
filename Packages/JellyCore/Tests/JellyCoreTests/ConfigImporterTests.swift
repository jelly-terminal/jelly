import Testing
@testable import JellyCore

struct ConfigImporterTests {
    private func merge(_ incoming: String, into current: String) throws -> String {
        let plan = ConfigImporter.plan(importing: incoming, currentConfig: current, existingThemeIDs: [])
        return try ConfigImporter.apply(plan, to: current)
    }

    @Test func replacesValuesInPlaceAndKeepsComments() throws {
        let current = """
        # my config
        [settings]
        theme = "nord" # favourite
        scrollback = 5000

        [settings.font]
        # the font I like
        family = "Menlo"
        size = 12
        """
        let result = try merge("""
        [settings]
        theme = "dracula"
        [settings.font]
        size = 14
        """, into: current)

        #expect(result == """
        # my config
        [settings]
        theme = "dracula" # favourite
        scrollback = 5000

        [settings.font]
        # the font I like
        family = "Menlo"
        size = 14
        """)
    }

    @Test func addsMissingKeysToTheRightTable() throws {
        let current = """
        [settings]
        theme = "nord"

        [keybinds]
        "cmd+d" = "split.right"
        """
        let result = try merge("""
        [settings]
        scrollback = 20000
        font.size = 15
        [settings.window]
        blur = 10
        [keybinds]
        "cmd+shift+t" = "tab.new"
        """, into: current)

        let document = ConfigDocument(parsing: result)
        #expect(document.diagnostics.isEmpty)
        #expect(document.settings.theme == .fixed("nord"))
        #expect(document.settings.scrollback == 20000)
        #expect(document.settings.font.size == 15)
        #expect(document.settings.window.blur == 10)
        #expect(document.keybinds[KeyChord("cmd+d")!] == .splitRight)
        #expect(document.keybinds[KeyChord("cmd+shift+t")!] == .tabNew)
        #expect(result.hasPrefix("[settings]\ntheme = \"nord\"\nscrollback = 20000\n"))
    }

    @Test func mergesIntoInlineTables() throws {
        let result = try merge("""
        [settings.window]
        padding = { y = 4 }
        """, into: """
        [settings]
        window = { padding = { x = 20, y = 8 }, blur = 5 }
        """)

        let settings = ConfigDocument(parsing: result).settings
        #expect(settings.window.paddingX == 20)
        #expect(settings.window.paddingY == 4)
        #expect(settings.window.blur == 5)
    }

    @Test func createsTheFileContentsFromNothing() throws {
        let result = try merge("""
        [settings]
        theme = { light = "jelly-light", dark = "nord" }
        """, into: "")

        #expect(ConfigDocument(parsing: result).settings.theme == .adaptive(light: "jelly-light", dark: "nord"))
    }

    @Test func planSkipsUnchangedValuesAndFlagsReplacedThemes() {
        let incoming = """
        [settings]
        scrollback = 5000
        cursor.style = "bar"

        [[theme]]
        id = "nord"
        name = "Nord"
        background = "#2e3440"
        foreground = "#d8dee9"
        palette = ["#000", "#111", "#222", "#333", "#444", "#555", "#666", "#777",
                   "#888", "#999", "#aaa", "#bbb", "#ccc", "#ddd", "#eee", "#fff"]

        [[theme]]
        id = "mine"
        name = "Mine"
        background = "#000"
        foreground = "#fff"
        palette = ["#000", "#111", "#222", "#333", "#444", "#555", "#666", "#777",
                   "#888", "#999", "#aaa", "#bbb", "#ccc", "#ddd", "#eee", "#fff"]
        """
        let plan = ConfigImporter.plan(
            importing: incoming,
            currentConfig: "[settings]\nscrollback = 5000\n",
            existingThemeIDs: ["nord"]
        )

        #expect(plan.settingChanges.map(\.key) == ["cursor.style"])
        #expect(plan.themes.map { "\($0.theme.id):\($0.replaces)" } == ["nord:true", "mine:false"])
        #expect(plan.summary == "Adds 1 theme, updates 1 theme, changes 1 setting")
    }

    @Test func refusesToEditABrokenConfig() {
        let plan = ConfigImporter.plan(importing: "[settings]\nblur = 1\n", currentConfig: "[settings\n", existingThemeIDs: [])
        #expect(!plan.canApply)
        #expect(plan.diagnostics.last?.line == 1)
    }
}
