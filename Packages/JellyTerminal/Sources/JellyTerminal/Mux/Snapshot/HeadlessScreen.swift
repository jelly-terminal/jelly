import SwiftTerm

final class HeadlessScreen {
    private(set) var terminal: Terminal!
    private(set) var title = ""
    var onReply: ((ArraySlice<UInt8>) -> Void)?

    private var primaryScreen: PrimaryScreen?
    private var replies: [UInt8]?

    init(cols: Int, rows: Int, scrollback: Int) {
        var options = TerminalOptions.default
        options.cols = max(cols, 1)
        options.rows = max(rows, 1)
        options.scrollback = scrollback
        terminal = Terminal(delegate: self, options: options)
    }

    func feed(_ bytes: ArraySlice<UInt8>) {
        if !terminal.isCurrentBufferAlternate, let offset = AlternateScreenScanner.enterOffset(in: bytes) {
            terminal.feed(buffer: bytes[..<offset])
            primaryScreen = PrimaryScreen(capturing: terminal)
            terminal.feed(buffer: bytes[offset...])
        } else {
            terminal.feed(buffer: bytes)
        }
        if !terminal.isCurrentBufferAlternate { primaryScreen = nil }
    }

    func resize(cols: Int, rows: Int) {
        terminal.resize(cols: max(cols, 1), rows: max(rows, 1))
    }

    func snapshot() -> [UInt8] {
        ScreenSnapshot.render(terminal, primary: primaryScreen, modes: modes(), title: title)
    }

    func modes() -> TerminalModes {
        replies = []
        terminal.feed(byteArray: TerminalModes.queries)
        let modes = TerminalModes.parse(replies ?? [])
        replies = nil
        return modes
    }
}

extension HeadlessScreen: TerminalDelegate {
    func send(source: Terminal, data: ArraySlice<UInt8>) {
        if replies != nil {
            replies? += data
        } else {
            onReply?(data)
        }
    }

    func setTerminalTitle(source: Terminal, title: String) {
        self.title = title
    }
}
