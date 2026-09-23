import Testing
@testable import JellyCore

struct MarkdownParserTests {
    @Test func headingsRulesAndSetextAreToldApart() {
        let blocks = MarkdownParser.parse("""
        # Title ##
        Sub
        ---
        * * *
        #nope
        """)
        #expect(blocks == [
            .heading(level: 1, text: "Title"),
            .heading(level: 2, text: "Sub"),
            .rule,
            .paragraph("#nope"),
        ])
    }

    @Test func paragraphsJoinSoftBreaksAndKeepHardBreaks() {
        let blocks = MarkdownParser.parse("one\ntwo  \nthree\\\nfour\n\n![logo](docs/logo.png)")
        #expect(blocks == [.paragraph("one two\nthree\nfour"), .image(alt: "logo", source: "docs/logo.png")])
    }

    @Test func fencesKeepContentAndRunToTheEndWhenUnclosed() {
        let blocks = MarkdownParser.parse("""
          ````swift title
          let a = 1
          ```
          ````
        ~~~
        # not a heading
        """)
        #expect(blocks == [
            .code(language: "swift", text: "let a = 1\n```"),
            .code(language: nil, text: "# not a heading"),
        ])
    }

    @Test func listsNestTasksCodeAndLazyLines() {
        let blocks = MarkdownParser.parse("""
        - [x] done
        - [ ] todo
          lazy? no, indented

          ```sh
          make
          ```
          1. inner
          2) other
        continued

        3. three
        4. four
        """)
        let inner = MarkdownBlock.list(MarkdownList(start: 1, items: [
            .init(blocks: [.paragraph("inner")]),
        ]))
        let other = MarkdownBlock.list(MarkdownList(start: 2, items: [
            .init(blocks: [.paragraph("other continued")]),
        ]))
        #expect(blocks == [
            .list(MarkdownList(items: [
                .init(checked: true, blocks: [.paragraph("done")]),
                .init(checked: false, blocks: [
                    .paragraph("todo lazy? no, indented"),
                    .code(language: "sh", text: "make"),
                    inner,
                    other,
                ]),
            ])),
            .list(MarkdownList(start: 3, items: [
                .init(blocks: [.paragraph("three")]),
                .init(blocks: [.paragraph("four")]),
            ])),
        ])
    }

    @Test func quotesTakeLazyContinuationLines() {
        let blocks = MarkdownParser.parse("> **Note**\nlazy\n> - item\n\nafter")
        #expect(blocks == [
            .quote([.paragraph("**Note** lazy"), .list(MarkdownList(items: [.init(blocks: [.paragraph("item")])]))]),
            .paragraph("after"),
        ])
    }

    @Test func tablesSplitOnUnescapedPipesOutsideCode() {
        let blocks = MarkdownParser.parse("""
        | Key | Default | Notes |
        |:----|:-------:|------:|
        | `a|b` | x \\| y | extra | dropped |
        | short |
        """)
        #expect(blocks == [.table(MarkdownTable(
            alignments: [.leading, .center, .trailing],
            header: ["Key", "Default", "Notes"],
            rows: [["`a|b`", "x | y", "extra"], ["short", "", ""]]
        ))])
    }

    @Test func outlineAnchorsMatchGitHubAndDeduplicate() {
        let document = MarkdownDocument("# Getting *started*\n## [Config](config.md) & `keys`\n# Getting started\n## snake_case")
        #expect(document.outline.map(\.anchor) == ["getting-started", "config--keys", "getting-started-1", "snake_case"])
        #expect(document.outline.map(\.title)[1] == "Config & keys")
    }
}
