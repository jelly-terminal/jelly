import SwiftTerm

struct PrimaryScreen {
    var lines: [BufferLine]
    var cursorX: Int
    var cursorY: Int

    init(capturing terminal: Terminal) {
        lines = Self.lines(of: terminal)
        cursorX = terminal.buffer.x
        cursorY = terminal.buffer.y
    }

    static func lines(of terminal: Terminal) -> [BufferLine] {
        var lines: [BufferLine] = []
        var row = terminal.buffer.totalLinesTrimmed
        while let line = terminal.getScrollInvariantLine(row: row) {
            lines.append(line)
            row += 1
        }
        return lines
    }
}
