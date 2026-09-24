import SwiftTerm

struct ScreenSnapshot {
    private(set) var bytes: [UInt8] = []
    private let terminal: Terminal
    private let blank: Attribute
    private var pen: Attribute

    private init(terminal: Terminal) {
        self.terminal = terminal
        blank = BufferLine(cols: 1)[0].attribute
        pen = blank
    }

    static func render(_ terminal: Terminal, primary: PrimaryScreen?, modes: TerminalModes, title: String) -> [UInt8] {
        var snapshot = ScreenSnapshot(terminal: terminal)
        snapshot.write(terminal: terminal, primary: primary, modes: modes, title: title)
        return snapshot.bytes
    }

    private mutating func write(terminal: Terminal, primary: PrimaryScreen?, modes: TerminalModes, title: String) {
        if !title.isEmpty { text("\u{1B}]2;\(title)\u{07}") }
        if let directory = terminal.hostCurrentDirectory, !directory.isEmpty {
            text("\u{1B}]7;\(directory)\u{07}")
        }
        if terminal.isCurrentBufferAlternate {
            if let primary {
                lines(primary.lines)
                resetPen()
                text("\u{1B}[\(primary.cursorY + 1);\(min(primary.cursorX, terminal.cols - 1) + 1)H")
            }
            text("\u{1B}[?1049h\u{1B}[H")
            lines((0..<terminal.rows).compactMap { terminal.getLine(row: $0) })
        } else {
            lines(PrimaryScreen.lines(of: terminal))
        }
        resetPen()

        let buffer = terminal.buffer
        if buffer.scrollTop != 0 || buffer.scrollBottom != terminal.rows - 1 {
            text("\u{1B}[\(buffer.scrollTop + 1);\(buffer.scrollBottom + 1)r")
        }
        bytes += modes.restoreSequence
        let keyboard = terminal.keyboardEnhancementFlags.rawValue
        if keyboard != 0 { text("\u{1B}[=\(keyboard);1u") }
        let row = modes.isOriginMode ? buffer.y - buffer.scrollTop : buffer.y
        text("\u{1B}[\(max(row, 0) + 1);\(min(buffer.x, terminal.cols - 1) + 1)H")
        setPen(terminal.currentAttribute)
    }

    private mutating func lines(_ lines: [BufferLine]) {
        let cols = terminal.cols
        for (index, line) in lines.enumerated() {
            let isLast = index == lines.count - 1
            let continues = !isLast && lines[index + 1].isWrapped
            let end = continues ? min(line.count, cols) : contentLength(of: line, cols: cols)
            var column = 0
            while column < end {
                let cell = line[column]
                let width = Int(cell.width)
                guard width > 0 else {
                    column += 1
                    continue
                }
                setPen(cell.attribute)
                let character = terminal.getCharacter(for: cell)
                if character == "\0" {
                    bytes.append(0x20)
                } else {
                    bytes += Array(String(character).utf8)
                }
                column += width
            }
            if !isLast, !continues {
                resetPen()
                text("\r\n")
            }
        }
    }

    private func contentLength(of line: BufferLine, cols: Int) -> Int {
        var length = min(line.count, cols)
        while length > 0 {
            let index = length - 1
            let cell = line[index]
            if cell.attribute != blank { break }
            if line.hasContent(index: index) {
                let character = terminal.getCharacter(for: cell)
                if character != " " && character != "\0" { break }
            }
            length -= 1
        }
        return length
    }

    private mutating func resetPen() {
        guard pen != blank else { return }
        text("\u{1B}[0m")
        pen = blank
    }

    private mutating func setPen(_ attribute: Attribute) {
        guard attribute != pen else { return }
        text(Self.sgr(attribute))
        pen = attribute
    }

    private mutating func text(_ string: String) {
        bytes += Array(string.utf8)
    }

    static func sgr(_ attribute: Attribute) -> String {
        var parameters = ["0"]
        let style = attribute.style
        if style.contains(.bold) { parameters.append("1") }
        if style.contains(.dim) { parameters.append("2") }
        if style.contains(.italic) { parameters.append("3") }
        if style.contains(.underline) {
            switch attribute.underlineStyle {
            case .none, .single: parameters.append("4")
            case .double: parameters.append("4:2")
            case .curly: parameters.append("4:3")
            case .dotted: parameters.append("4:4")
            case .dashed: parameters.append("4:5")
            }
        }
        if style.contains(.blink) { parameters.append("5") }
        if style.contains(.inverse) { parameters.append("7") }
        if style.contains(.invisible) { parameters.append("8") }
        if style.contains(.crossedOut) { parameters.append("9") }
        parameters += color(attribute.fg, base: 30, bright: 90, extended: 38)
        parameters += color(attribute.bg, base: 40, bright: 100, extended: 48)
        if let underline = attribute.underlineColor {
            parameters += color(underline, base: nil, bright: nil, extended: 58)
        }
        return "\u{1B}[" + parameters.joined(separator: ";") + "m"
    }

    private static func color(_ color: Attribute.Color, base: Int?, bright: Int?, extended: Int) -> [String] {
        switch color {
        case .ansi256(let code):
            if code < 8, let base { return ["\(base + Int(code))"] }
            if code < 16, let bright { return ["\(bright + Int(code) - 8)"] }
            return ["\(extended)", "5", "\(code)"]
        case .trueColor(let red, let green, let blue):
            return ["\(extended)", "2", "\(red)", "\(green)", "\(blue)"]
        case .defaultColor, .defaultInvertedColor:
            return []
        }
    }
}
