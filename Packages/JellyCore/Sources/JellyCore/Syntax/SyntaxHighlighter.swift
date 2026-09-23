public enum SyntaxHighlighter {
    public static func tokens(in text: String, language: SyntaxLanguage) -> [SyntaxToken] {
        let bytes = Array(text.utf8)
        guard !language.diff else { return diffTokens(bytes) }
        var scanner = Scanner(bytes: bytes, language: language)
        return scanner.run()
    }

    public static func lines(of text: String, tokens: [SyntaxToken]) -> [[SyntaxToken]] {
        var result: [[SyntaxToken]] = []
        var lineStart = 0
        var tokenIndex = 0
        var pending: [SyntaxToken] = []
        let bytes = Array(text.utf8)
        for offset in 0...bytes.count where offset == bytes.count || bytes[offset] == newline {
            let line = lineStart..<offset
            while tokenIndex < tokens.count, tokens[tokenIndex].range.lowerBound < offset {
                pending.append(tokens[tokenIndex])
                tokenIndex += 1
            }
            var carried: [SyntaxToken] = []
            var lineTokens: [SyntaxToken] = []
            for token in pending {
                let clipped = max(token.range.lowerBound, line.lowerBound)..<min(token.range.upperBound, line.upperBound)
                if !clipped.isEmpty {
                    lineTokens.append(SyntaxToken(token.kind, (clipped.lowerBound - lineStart)..<(clipped.upperBound - lineStart)))
                }
                if token.range.upperBound > offset + 1 { carried.append(token) }
            }
            result.append(lineTokens)
            pending = carried
            lineStart = offset + 1
        }
        return result
    }

    private static let newline = UInt8(ascii: "\n")

    private static func diffTokens(_ bytes: [UInt8]) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        var start = 0
        for offset in 0...bytes.count where offset == bytes.count || bytes[offset] == newline {
            if start < offset {
                let kind: SyntaxToken.Kind? = switch bytes[start] {
                case UInt8(ascii: "+"): .inserted
                case UInt8(ascii: "-"): .deleted
                case UInt8(ascii: "@"): .keyword
                default: nil
                }
                if let kind { tokens.append(SyntaxToken(kind, start..<offset)) }
            }
            start = offset + 1
        }
        return tokens
    }

    private struct Scanner {
        let bytes: [UInt8]
        let language: SyntaxLanguage
        let lineComments: [[UInt8]]
        let blockComments: [([UInt8], [UInt8])]
        let strings: [[UInt8]]
        var tokens: [SyntaxToken] = []
        var i = 0

        init(bytes: [UInt8], language: SyntaxLanguage) {
            self.bytes = bytes
            self.language = language
            lineComments = language.lineComments.map { Array($0.utf8) }
            blockComments = language.blockComments.map { (Array($0.open.utf8), Array($0.close.utf8)) }
            strings = language.strings.map { Array($0.utf8) }.sorted { $0.count > $1.count }
        }

        mutating func run() -> [SyntaxToken] {
            while i < bytes.count {
                let start = i
                let byte = bytes[i]
                if let block = blockComments.first(where: { matches($0.0, at: i) }) {
                    i = find(block.1, from: i + block.0.count).map { $0 + block.1.count } ?? bytes.count
                    emit(.comment, start)
                } else if lineComments.contains(where: { matches($0, at: i) }) {
                    skipToLineEnd()
                    emit(.comment, start)
                } else if let delimiter = strings.first(where: { matches($0, at: i) }) {
                    scanString(delimiter)
                    emit(.string, start)
                } else if language.tags, byte == ascii("<") {
                    i += 1
                    if i < bytes.count, bytes[i] == ascii("/") { i += 1 }
                    let nameStart = i
                    while i < bytes.count, isWord(bytes[i]) || bytes[i] == ascii("-") || bytes[i] == ascii(":") { i += 1 }
                    if i > nameStart { tokens.append(SyntaxToken(.tag, nameStart..<i)) }
                } else if language.shellVariables, byte == ascii("$") {
                    scanVariable()
                    emit(.variable, start)
                } else if isDigit(byte), start == 0 || !isWord(bytes[start - 1]) {
                    while i < bytes.count, isWord(bytes[i]) || bytes[i] == ascii(".") && i + 1 < bytes.count && isDigit(bytes[i + 1]) { i += 1 }
                    emit(.number, start)
                } else if (byte == ascii("@") || byte == ascii("#")) && i + 1 < bytes.count && isWordStart(bytes[i + 1]) {
                    i += 1
                    while i < bytes.count, isWord(bytes[i]) { i += 1 }
                    emit(.keyword, start)
                } else if isWordStart(byte) {
                    while i < bytes.count, isWord(bytes[i]) { i += 1 }
                    classifyWord(start)
                } else {
                    i += 1
                }
            }
            return tokens
        }

        private mutating func classifyWord(_ start: Int) {
            let word = String(decoding: bytes[start..<i], as: UTF8.self)
            if language.keywords.contains(word) {
                emit(.keyword, start)
            } else if language.literals.contains(word) {
                emit(.literal, start)
            } else if nextNonSpace() == ascii("(") {
                emit(.function, start)
            } else if language.capitalizedTypes, let first = word.first, first.isUppercase, word.contains(where: \.isLowercase) {
                emit(.type, start)
            }
        }

        private mutating func scanString(_ delimiter: [UInt8]) {
            let multiline = language.multilineStrings.contains(String(decoding: delimiter, as: UTF8.self))
            i += delimiter.count
            while i < bytes.count {
                if bytes[i] == ascii("\\"), delimiter != [ascii("'")] || !language.shellVariables {
                    i += 2
                } else if matches(delimiter, at: i) {
                    i += delimiter.count
                    return
                } else if bytes[i] == SyntaxHighlighter.newline, !multiline {
                    return
                } else {
                    i += 1
                }
            }
            i = min(i, bytes.count)
        }

        private mutating func scanVariable() {
            i += 1
            guard i < bytes.count else { return }
            if bytes[i] == ascii("{") {
                i = find([ascii("}")], from: i).map { $0 + 1 } ?? i
            } else {
                while i < bytes.count, isWord(bytes[i]) { i += 1 }
            }
        }

        private mutating func skipToLineEnd() {
            while i < bytes.count, bytes[i] != SyntaxHighlighter.newline { i += 1 }
        }

        private mutating func emit(_ kind: SyntaxToken.Kind, _ start: Int) {
            let end = min(i, bytes.count)
            if end > start { tokens.append(SyntaxToken(kind, start..<end)) }
        }

        private func nextNonSpace() -> UInt8? {
            var j = i
            while j < bytes.count, bytes[j] == ascii(" ") { j += 1 }
            return j < bytes.count ? bytes[j] : nil
        }

        private func matches(_ pattern: [UInt8], at index: Int) -> Bool {
            guard !pattern.isEmpty, index + pattern.count <= bytes.count else { return false }
            for offset in 0..<pattern.count where bytes[index + offset] != pattern[offset] { return false }
            return true
        }

        private func find(_ pattern: [UInt8], from index: Int) -> Int? {
            var j = index
            while j + pattern.count <= bytes.count {
                if matches(pattern, at: j) { return j }
                j += 1
            }
            return nil
        }

        private func ascii(_ scalar: Unicode.Scalar) -> UInt8 { UInt8(ascii: scalar) }
        private func isDigit(_ byte: UInt8) -> Bool { byte >= 48 && byte <= 57 }
        private func isWordStart(_ byte: UInt8) -> Bool { byte == 95 || (byte | 0x20) >= 97 && (byte | 0x20) <= 122 || byte >= 0x80 }
        private func isWord(_ byte: UInt8) -> Bool { isWordStart(byte) || isDigit(byte) }
    }
}
