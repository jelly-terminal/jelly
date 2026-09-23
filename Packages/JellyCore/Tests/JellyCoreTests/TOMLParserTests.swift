import Testing
@testable import JellyCore

struct TOMLParserTests {
    @Test func parsesTheShapesConfigFilesUse() throws {
        let table = try TOMLParser.parse(#"""
        # comment
        title = "a \"quoted\" \u00e9 string" # trailing
        literal = 'C:\path'
        block = """
        one \
          two"""
        numbers = [1_000, 0x1F, -3.5e2, inf]
        mixed = [
          "a", # inside
          "b",
        ]
        point = { x = 1, y.z = 2 }

        [settings.font]
        family = "FiraCode Nerd Font"
        "quoted key" = true

        [[theme]]
        id = "a"
        [[theme]]
        id = "b"
        """#)

        #expect(table["title"] == .string("a \"quoted\" é string"))
        #expect(table["literal"] == .string(#"C:\path"#))
        #expect(table["block"] == .string("one two"))
        #expect(table["numbers"] == .array([.integer(1000), .integer(31), .float(-350), .float(.infinity)]))
        #expect(table["mixed"] == .array([.string("a"), .string("b")]))
        #expect(table.value(at: ["point", "y", "z"]) == .integer(2))
        #expect(table.value(at: ["settings", "font", "family"]) == .string("FiraCode Nerd Font"))
        #expect(table.value(at: ["settings", "font", "quoted key"]) == .bool(true))
        guard case .array(let themes)? = table["theme"] else { Issue.record("no themes"); return }
        #expect(themes.compactMap { $0.table?["id"] } == [.string("a"), .string("b")])
        #expect(table.line(of: "mixed") == 8)
    }

    @Test(arguments: [
        ("a = 1\nb = \n", 2),
        ("a = 1\na = 2\n", 2),
        ("[t]\nx = 1\n[t]\n", 3),
        ("a = \"open\n", 1),
        ("a = 1 b = 2\n", 1),
    ])
    func reportsTheLineOfAnError(source: String, line: Int) {
        #expect(throws: TOMLError.self) { try TOMLParser.parse(source) }
        do {
            _ = try TOMLParser.parse(source)
        } catch {
            #expect(error.line == line)
        }
    }
}
