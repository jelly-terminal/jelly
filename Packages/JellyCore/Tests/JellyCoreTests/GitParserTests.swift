import Testing
@testable import JellyCore

struct GitParserTests {
    @Test func statusReadsBranchAndChangesInEveryArea() {
        let output = [
            "# branch.oid 1a2b3c",
            "# branch.head feature/diff",
            "# branch.upstream origin/feature/diff",
            "# branch.ab +2 -1",
            "1 MM N... 100644 100644 100644 aaa bbb Sources/My File.swift",
            "1 .D N... 100644 100644 000000 aaa aaa gone.txt",
            "2 R. N... 100644 100644 100644 aaa bbb R100 new name.md",
            "old name.md",
            "u UU N... 100644 100644 100644 100644 aaa bbb ccc both.txt",
            "? notes/todo.txt",
            "! ignored.log",
        ].joined(separator: "\0") + "\0"
        let status = GitStatusParser.parse(output)
        #expect(status.branch == "feature/diff" && status.commit == "1a2b3c" && status.upstream == "origin/feature/diff")
        #expect(status.ahead == 2 && status.behind == 1)
        #expect(status.changes == [
            GitChange(path: "Sources/My File.swift", area: .staged, kind: .modified),
            GitChange(path: "Sources/My File.swift", area: .unstaged, kind: .modified),
            GitChange(path: "gone.txt", area: .unstaged, kind: .deleted),
            GitChange(path: "new name.md", originalPath: "old name.md", area: .staged, kind: .renamed),
            GitChange(path: "both.txt", area: .conflicted, kind: .conflicted),
            GitChange(path: "notes/todo.txt", area: .untracked, kind: .untracked),
        ])
    }

    @Test func statusHandlesDetachedAndInitialHeads() {
        let status = GitStatusParser.parse("# branch.oid (initial)\0# branch.head (detached)\0")
        #expect(status.branch == nil && status.commit == nil && status.changes.isEmpty)
    }

    @Test func diffNumbersLinesAcrossHunks() {
        let diff = DiffParser.parse("""
        diff --git a/a.swift b/a.swift
        index 1..2 100644
        --- a/a.swift
        +++ b/a.swift
        @@ -1,3 +1,3 @@ struct A {
         one
        -two
        +TWO
         three
        @@ -10 +10,2 @@
         ten
        +eleven

        """)
        #expect(diff.hunks.count == 2)
        #expect(diff.hunks[0].header == "@@ -1,3 +1,3 @@ struct A {")
        #expect(diff.hunks[0].lines.map(\.text) == ["one", "two", "TWO", "three"])
        #expect(diff.hunks[0].lines.map(\.oldNumber) == [1, 2, nil, 3])
        #expect(diff.hunks[0].lines.map(\.newNumber) == [1, nil, 2, 3])
        #expect(diff.hunks[1].lines.map(\.newNumber) == [10, 11])
        #expect(diff.additions == 2 && diff.deletions == 1)
    }

    @Test func diffKeepsHeaderLookalikesInsideHunks() {
        let diff = DiffParser.parse("""
        @@ -1,2 +0,0 @@
        --- a/not-a-header
        -\\ still content
        \\ No newline at end of file
        diff --git a/b b/b
        --- a/b
        +++ b/b
        @@ -0,0 +1 @@
        +++ b/also content
        """)
        #expect(diff.hunks.count == 2)
        #expect(diff.hunks[0].lines.map(\.text) == ["-- a/not-a-header", "\\ still content"])
        #expect(diff.hunks[0].lines.map(\.missingNewline) == [false, true])
        #expect(diff.hunks[1].lines.map(\.text) == ["++ b/also content"])
    }

    @Test func diffFlagsBinaryFiles() {
        let diff = DiffParser.parse("diff --git a/i.png b/i.png\nBinary files a/i.png and b/i.png differ\n")
        #expect(diff.isBinary && diff.hunks.isEmpty)
    }
}
