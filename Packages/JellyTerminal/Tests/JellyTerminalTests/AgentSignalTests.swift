import Testing
@testable import JellyTerminal

struct AgentSignalTests {
    private func scan(_ chunks: [String]) -> [String] {
        var scanner = NotificationScanner()
        return chunks.flatMap { scanner.scan(ArraySlice(Array($0.utf8))) }
    }

    @Test func readsOSC9AndOSC777WithEitherTerminator() {
        #expect(scan(["a\u{1B}]9;Build done\u{07}b"]) == ["Build done"])
        #expect(scan(["\u{1B}]777;notify;Claude;Needs permission\u{1B}\\"]) == ["Claude: Needs permission"])
    }

    @Test func sequencesSplitAcrossChunksAreJoined() {
        #expect(scan(["\u{1B}", "]9;Wai", "ting\u{1B}", "\\"]) == ["Waiting"])
    }

    @Test func ignoresProgressReportsAndOtherCodes() {
        #expect(scan(["\u{1B}]9;4;1;50\u{07}", "\u{1B}]9;12\u{07}", "\u{1B}]0;title\u{07}", "\u{1B}]133;A\u{07}"]).isEmpty)
        #expect(scan(["\u{1B}]9;3 files changed\u{07}"]) == ["3 files changed"])
    }

    @Test func dropsOversizedAndCancelledSequences() {
        let huge = String(repeating: "x", count: NotificationScanner.maxLength + 1)
        #expect(scan(["\u{1B}]9;\(huge)\u{07}"]).isEmpty)
        #expect(scan(["\u{1B}]9;gone\u{18}\u{1B}]9;kept\u{07}"]) == ["kept"])
    }

    @Test func parsesProcessArguments() {
        var bytes: [UInt8] = [3, 0, 0, 0]
        bytes += Array("/opt/homebrew/bin/node".utf8) + [0, 0, 0, 0]
        bytes += Array("node".utf8) + [0] + Array("/opt/homebrew/bin/codex".utf8) + [0] + Array("--full-auto".utf8) + [0]
        bytes += Array("PATH=/usr/bin".utf8) + [0]
        let identity = ProcessArguments.parse(bytes[...])
        #expect(identity?.executable == "/opt/homebrew/bin/node")
        #expect(identity?.arguments == ["node", "/opt/homebrew/bin/codex", "--full-auto"])
    }
}
