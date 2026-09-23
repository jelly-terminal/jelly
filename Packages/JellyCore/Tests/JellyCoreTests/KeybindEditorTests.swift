import Testing
@testable import JellyCore

struct KeybindEditorTests {
    let source = """
    [settings]
    scrollback = 5000 # keep

    [keybinds]
    # mine
    "cmd+k" = "split.right"
    "super+p" = "find"
    """

    @Test func removeDeletesTheLineAndKeepsComments() throws {
        var editor = TOMLEditor(source + "\n[settings.window]\npadding = { x = 4, y = 2 }\n")
        try editor.remove(at: ["keybinds", "super+p"])
        try editor.remove(at: ["settings", "window", "padding", "x"])
        try editor.remove(at: ["settings", "missing"])
        #expect(!editor.source.contains("super+p"))
        #expect(editor.source.contains("# mine\n\"cmd+k\" = \"split.right\"\n"))
        #expect(editor.source.contains("scrollback = 5000 # keep"))
        #expect(editor.source.contains("padding = { y = 2 }"))
    }

    @Test func bindingReleasesOldChordsAndReusesWrittenKeys() throws {
        let edited = try KeybindEditor.bind(KeyChord("cmd+p"), to: .splitDown, in: source)
        let keybinds = Keybinds.decode(try TOMLParser.parse(edited)["keybinds"]!.table!).0
        #expect(keybinds.chords(for: .splitDown) == [KeyChord("cmd+p")!])
        #expect(keybinds[KeyChord("cmd+shift+d")!] == nil)
        #expect(edited.contains("\"super+p\" = \"split.down\""))
        #expect(edited.contains("\"cmd+shift+d\" = \"none\""))
    }

    @Test func resetRestoresDefaultsAndDropsCustomChords() throws {
        let unbound = try KeybindEditor.bind(nil, to: .splitRight, in: source)
        let reset = try KeybindEditor.reset(.splitRight, in: unbound)
        let keybinds = Keybinds.decode(try TOMLParser.parse(reset)["keybinds"]!.table!).0
        #expect(keybinds.chords(for: .splitRight) == Keybinds.defaults.chords(for: .splitRight))
        #expect(!reset.contains("cmd+d"))
        #expect(reset.contains("\"cmd+k\" = \"none\""))
        #expect(reset.contains("\"super+p\" = \"find\""))
    }

    @Test func catalogNamesParseBack() {
        for action in KeyAction.catalog {
            #expect(KeyAction(action.name) == action)
        }
    }
}
