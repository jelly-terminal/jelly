import Testing
@testable import JellyCore

struct ActivityTests {
    @Test func descendantsWalkDepthFirstWithDepths() {
        let tree = ProcessTree(records: [
            ProcessRecord(pid: 10, parent: 1, name: "fish"),
            ProcessRecord(pid: 30, parent: 10, name: "node"),
            ProcessRecord(pid: 20, parent: 10, name: "npm"),
            ProcessRecord(pid: 21, parent: 20, name: "esbuild"),
            ProcessRecord(pid: 99, parent: 1, name: "other"),
        ])
        #expect(tree.descendants(of: 10) == [
            .init(pid: 10, depth: 0), .init(pid: 20, depth: 1), .init(pid: 21, depth: 2), .init(pid: 30, depth: 1),
        ])
        #expect(tree.descendants(of: 42).isEmpty)
    }

    @Test func descendantsSurviveCycles() {
        let tree = ProcessTree(records: [
            ProcessRecord(pid: 1, parent: 2, name: "a"),
            ProcessRecord(pid: 2, parent: 1, name: "b"),
        ])
        #expect(tree.descendants(of: 1).map(\.pid) == [1, 2])
    }

    @Test func summaryReadsLikeTheTypedCommand() {
        func summary(_ arguments: [String]) -> String {
            ProcessIdentity(executable: arguments[0], arguments: arguments).summary
        }
        #expect(summary(["-fish"]) == "fish")
        #expect(summary(["node", "/opt/homebrew/bin/npm", "run", "dev"]) == "npm run dev")
        #expect(summary(["node", "server.js"]) == "node server.js")
        #expect(summary(["/usr/bin/python3", "-m", "http.server", "8000", "--bind"]) == "python3 -m http.server 8000")
        #expect(summary(["vim", "/Users/me/project/README.md"]) == "vim README.md")
        #expect(summary(["curl", "https://example.com/a/b"]) == "curl https://example.com/a/b")
    }
}
