import SwiftTerm
import Testing
@testable import JellyTerminal

struct MuxTests {
    private func screen(_ output: String, cols: Int = 20, rows: Int = 4) -> HeadlessScreen {
        let screen = HeadlessScreen(cols: cols, rows: rows, scrollback: 100)
        screen.feed(ArraySlice(Array(output.utf8)))
        return screen
    }

    private func restored(_ source: HeadlessScreen) -> HeadlessScreen {
        let copy = HeadlessScreen(cols: source.terminal.cols, rows: source.terminal.rows, scrollback: 100)
        copy.feed(ArraySlice(source.snapshot()))
        return copy
    }

    private func text(_ screen: HeadlessScreen) -> [String] {
        PrimaryScreen.lines(of: screen.terminal).map { $0.translateToString(trimRight: true) }
    }

    private func cursor(_ screen: HeadlessScreen) -> [Int] {
        [screen.terminal.buffer.x, screen.terminal.buffer.y]
    }

    @Test func scrollbackScreenAndCursorComeBack() {
        let lines = (1...10).map { "line \($0)" }.joined(separator: "\r\n")
        let source = screen(lines + "\r\n$ ls")
        let copy = restored(source)
        #expect(text(copy) == text(source))
        #expect(cursor(copy) == cursor(source))
    }

    @Test func wrappedLinesStaySoftWrapped() {
        let source = screen(String(repeating: "abcde", count: 9))
        let copy = restored(source)
        #expect(text(copy) == text(source))
        #expect(copy.terminal.getLine(row: 1)?.isWrapped == true)
        source.resize(cols: 45, rows: 4)
        copy.resize(cols: 45, rows: 4)
        #expect(text(copy) == text(source))
    }

    @Test func colorsAndStylesComeBack() {
        let source = screen("\u{1B}[1;31mred\u{1B}[0m \u{1B}[4:3;38;2;1;2;3;48;5;200mtc\u{1B}[0m \u{1B}[7;93mx\u{1B}[3m")
        let copy = restored(source)
        for column in 0..<9 {
            #expect(copy.terminal.getCharData(col: column, row: 0)?.attribute == source.terminal.getCharData(col: column, row: 0)?.attribute)
        }
        #expect(copy.terminal.currentAttribute == source.terminal.currentAttribute)
    }

    @Test func alternateScreenKeepsThePrimaryScreenBehindIt() {
        let source = screen("shell 1\r\nshell 2\r\n$ vim\u{1B}[?1049h\u{1B}[H\u{1B}[2Jeditor")
        let copy = restored(source)
        #expect(copy.terminal.isCurrentBufferAlternate)
        #expect(copy.terminal.getLine(row: 0)?.translateToString(trimRight: true) == "editor")
        #expect(cursor(copy) == cursor(source))
        let leave = ArraySlice(Array("\u{1B}[?1049l".utf8))
        source.feed(leave)
        copy.feed(leave)
        #expect(text(copy) == text(source))
        #expect(cursor(copy) == cursor(source))
    }

    @Test func modesScrollRegionAndKeyboardComeBack() {
        let source = screen("\u{1B}[?1h\u{1B}[?2004h\u{1B}[?1002h\u{1B}[?1006h\u{1B}[?25l\u{1B}[4h\u{1B}[=5;1u\u{1B}[2;3r\u{1B}[3;4H")
        let copy = restored(source)
        #expect(copy.modes() == source.modes())
        #expect(copy.terminal.applicationCursor)
        #expect(copy.terminal.bracketedPasteMode)
        #expect(copy.terminal.mouseMode == .buttonEventTracking)
        #expect(copy.terminal.keyboardEnhancementFlags == source.terminal.keyboardEnhancementFlags)
        #expect(copy.terminal.buffer.scrollTop == 1)
        #expect(copy.terminal.buffer.scrollBottom == 2)
        #expect(cursor(copy) == cursor(source))
    }

    @Test func titleAndDirectoryComeBack() {
        let source = screen("\u{1B}]2;build\u{07}\u{1B}]7;file://host/tmp/app\u{07}$ ")
        let copy = restored(source)
        #expect(copy.title == "build")
        #expect(copy.terminal.hostCurrentDirectory == source.terminal.hostCurrentDirectory)
    }

    @Test func modeRepliesParse() {
        let modes = TerminalModes.parse(Array("\u{1B}[?1;1$y\u{1B}[?25;2$y\u{1B}[?1000;0$y\u{1B}[4;1$y".utf8))
        #expect(modes.privateModes == [1: true, 25: false])
        #expect(modes.ansiModes == [4: true])
        #expect(String(decoding: modes.restoreSequence, as: UTF8.self) == "\u{1B}[?1h\u{1B}[?25l\u{1B}[4h")
    }

    @Test func findsAlternateScreenEntry() {
        let bytes = ArraySlice(Array("ab\u{1B}[?1049h".utf8))
        #expect(AlternateScreenScanner.enterOffset(in: bytes) == 2)
        #expect(AlternateScreenScanner.enterOffset(in: ArraySlice(Array("\u{1B}[?47h".utf8))) == 0)
        #expect(AlternateScreenScanner.enterOffset(in: ArraySlice(Array("\u{1B}[?1049l\u{1B}[?10490h".utf8))) == nil)
    }

    @Test func framesSplitAcrossReadsAreJoined() throws {
        let frames = [MuxFrame(.input, Array("ls\r".utf8)), MuxFrame(.opened, json: MuxOpened(pid: 42, restored: true))]
        var reader = MuxFrameReader()
        var decoded: [MuxFrame] = []
        for byte in frames.flatMap(\.encoded) {
            reader.append([byte])
            while let frame = try reader.next() { decoded.append(frame) }
        }
        #expect(decoded == frames)
        #expect(decoded[1].decode(MuxOpened.self)?.pid == 42)
    }

    @Test func rejectsUnknownAndOversizedFrames() {
        var unknown = MuxFrameReader()
        unknown.append([99, 0, 0, 0, 0])
        #expect(throws: MuxFrameReader.Failure.unknownMessage(99)) { try unknown.next() }
        var oversized = MuxFrameReader()
        oversized.append([MuxMessage.output.rawValue, 0xFF, 0xFF, 0xFF, 0x7F])
        #expect(throws: MuxFrameReader.Failure.oversized(0x7FFF_FFFF)) { try oversized.next() }
    }
}
