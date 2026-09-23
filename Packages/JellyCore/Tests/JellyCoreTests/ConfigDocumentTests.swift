import Testing
@testable import JellyCore

struct ConfigDocumentTests {
    @Test func invalidValuesFallBackAndReportTheirLine() {
        let document = ConfigDocument(parsing: """
        [settings]
        scrollback = "lots"
        confirm-quit = false
        tpyo = 1

        [settings.font]
        size = 1000
        family = "Iosevka"
        cell-height = "tall"

        [keybinds]
        "cmd+hyper+x" = "tab.new"
        "cmd+y" = "explode"
        """, file: "jelly.toml")

        #expect(document.settings.scrollback == Settings().scrollback)
        #expect(document.settings.confirmQuit == false)
        #expect(document.settings.font.size == 13)
        #expect(document.settings.font.family == "Iosevka")
        #expect(document.diagnostics.map(\.line) == [2, 4, 7, 9, 12, 13])
        #expect(document.diagnostics.allSatisfy { $0.file == "jelly.toml" })
    }

    @Test func syntaxErrorKeepsDefaults() {
        let document = ConfigDocument(parsing: "[settings]\nscrollback = 1\nfont = {\n")
        #expect(document.settings == Settings())
        #expect(document.diagnostics.count == 1)
    }

    @Test func noneUnbindsADefault() {
        let document = ConfigDocument(parsing: "[keybinds]\n\"cmd+k\" = \"none\"\n\"ctrl+shift+enter\" = \"text:\\\\e[13;2u\"\n")
        #expect(document.keybinds[KeyChord("cmd+k")!] == nil)
        #expect(document.keybinds[KeyChord("ctrl+shift+enter")!] == .text("\u{1B}[13;2u"))
    }

    @Test func themeNeedsSixteenValidColors() {
        let document = ConfigDocument(parsing: """
        [[theme]]
        id = "short"
        background = "#000"
        foreground = "#fff"
        palette = ["#000", "#111"]

        [[theme]]
        id = "bad"
        background = "black"
        foreground = "#fff"
        palette = ["#000", "#111", "#222", "#333", "#444", "#555", "#666", "#777",
                   "#888", "#999", "#aaa", "#bbb", "#ccc", "#ddd", "#eee", "#fff"]
        """)
        #expect(document.themes.isEmpty)
        #expect(document.diagnostics.map(\.line) == [5, 9])
    }

    @Test(arguments: [
        ("#0af", ThemeColor(red: 0, green: 0xAA, blue: 0xFF)),
        ("#1A2b3C", ThemeColor(red: 0x1A, green: 0x2B, blue: 0x3C)),
        ("#11223380", ThemeColor(red: 0x11, green: 0x22, blue: 0x33, alpha: 0x80)),
    ])
    func parsesHexColors(hex: String, color: ThemeColor) {
        #expect(ThemeColor(hex: hex) == color)
    }

    @Test(arguments: ["0af", "#0afx", "#12345", "#", "#ggg"])
    func rejectsBadHexColors(hex: String) {
        #expect(ThemeColor(hex: hex) == nil)
    }

    @Test func builtinThemesAllLoad() {
        let ids = Set(BuiltinThemes.all.map(\.id))
        #expect(ids.contains(BuiltinThemes.darkID))
        #expect(ids.contains(BuiltinThemes.lightID))
        #expect(ids.count == 8)
    }
}
