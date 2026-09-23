import Testing
@testable import JellyCore

struct SyntaxHighlighterTests {
    private func spans(_ text: String, _ language: String) -> [String] {
        let bytes = Array(text.utf8)
        return SyntaxHighlighter.tokens(in: text, language: SyntaxLanguage.named(language)!).map {
            "\($0.kind):" + String(decoding: bytes[$0.range], as: UTF8.self)
        }
    }

    @Test func swiftWordsStringsAndComments() {
        #expect(spans(#"let url: Request = make("a \"b\"", 0x1F) // done"#, "swift") == [
            "keyword:let", "type:Request", "function:make", #"string:"a \"b\"""#, "number:0x1F", "comment:// done",
        ])
    }

    @Test func aliasesResolveAndUnknownLanguagesDoNot() {
        #expect(SyntaxLanguage.named("TSX") != nil)
        #expect(SyntaxLanguage.named("zsh") != nil)
        #expect(SyntaxLanguage.named("brainfuck") == nil)
    }

    @Test func shellVariablesAndLiteralSingleQuotes() {
        #expect(spans(#"echo "$HOME" '${x}\' $PATH # note"#, "sh") == [
            "keyword:echo", #"string:"$HOME""#, #"string:'${x}\'"#, "variable:$PATH", "comment:# note",
        ])
    }

    @Test func multilineTokensAreSplitPerLine() {
        let text = "a /* one\ntwo */ b\n\"\"\"\nx\n\"\"\""
        let tokens = SyntaxHighlighter.tokens(in: text, language: SyntaxLanguage.named("swift")!)
        let lines = SyntaxHighlighter.lines(of: text, tokens: tokens)
        #expect(lines.count == 5)
        #expect(lines[0] == [SyntaxToken(.comment, 2..<8)])
        #expect(lines[1] == [SyntaxToken(.comment, 0..<6)])
        #expect(lines[2] == [SyntaxToken(.string, 0..<3)] && lines[3] == [SyntaxToken(.string, 0..<1)])
    }

    @Test func diffLinesAreMarked() {
        #expect(spans("@@ -1 +1 @@\n-old\n+new\n same", "diff") == ["keyword:@@ -1 +1 @@", "deleted:-old", "inserted:+new"])
    }
}
