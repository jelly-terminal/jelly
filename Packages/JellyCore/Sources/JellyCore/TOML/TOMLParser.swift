public struct TOMLParser {
    private let text: [Unicode.Scalar]
    private var index = 0
    private var line = 1
    private var root = TOMLTable()
    private var currentPath: [String] = []
    private var definedTables: Set<[String]> = []

    public static func parse(_ source: String) throws(TOMLError) -> TOMLTable {
        var parser = TOMLParser(source)
        return try parser.parseDocument()
    }

    init(_ source: String) {
        text = Array(source.unicodeScalars)
    }

    private mutating func parseDocument() throws(TOMLError) -> TOMLTable {
        root.isHeaderDefined = true
        while true {
            skipBlankLines()
            guard let c = peek() else { break }
            if c == "[" {
                if peek(1) == "[" {
                    try parseArrayTableHeader()
                } else {
                    try parseTableHeader()
                }
            } else {
                try parseKeyValue()
            }
            try expectLineEnd()
        }
        return root
    }

    private func peek(_ offset: Int = 0) -> Unicode.Scalar? {
        let i = index + offset
        return i < text.count ? text[i] : nil
    }

    private mutating func advance() {
        if text[index] == "\n" { line += 1 }
        index += 1
    }

    private func fail(_ message: String) -> TOMLError {
        TOMLError(line: line, message: message)
    }

    private mutating func skipSpaces() {
        while let c = peek(), c == " " || c == "\t" { advance() }
    }

    private mutating func skipComment() {
        guard peek() == "#" else { return }
        while let c = peek(), c != "\n" { advance() }
    }

    private mutating func skipBlankLines() {
        while true {
            skipSpaces()
            skipComment()
            guard let c = peek(), c == "\n" || c == "\r" else { return }
            advance()
        }
    }

    private mutating func skipWhitespaceInCollection() {
        while true {
            skipSpaces()
            skipComment()
            guard let c = peek(), c == "\n" || c == "\r" else { return }
            advance()
        }
    }

    private mutating func expectLineEnd() throws(TOMLError) {
        skipSpaces()
        skipComment()
        if peek() == "\r" { advance() }
        guard let c = peek() else { return }
        guard c == "\n" else { throw fail("expected end of line, found '\(c)'") }
        advance()
    }

    private mutating func parseTableHeader() throws(TOMLError) {
        let headerLine = line
        advance()
        skipSpaces()
        let path = try parseKey()
        skipSpaces()
        guard peek() == "]" else { throw fail("expected ']' to close table header") }
        advance()
        guard definedTables.insert(path).inserted else {
            throw fail("table [\(path.joined(separator: "."))] is defined twice")
        }
        try withTable(at: path, createdAt: headerLine) { table throws(TOMLError) in
            table.isHeaderDefined = true
            table.line = headerLine
        }
        currentPath = path
        let end = index
        try withTable(at: path, createdAt: headerLine) { table throws(TOMLError) in table.blockEnd = end }
    }

    private mutating func parseArrayTableHeader() throws(TOMLError) {
        let headerLine = line
        advance()
        advance()
        skipSpaces()
        let path = try parseKey()
        skipSpaces()
        guard peek() == "]", peek(1) == "]" else { throw fail("expected ']]' to close array of tables") }
        advance()
        advance()
        var element = TOMLTable()
        element.isHeaderDefined = true
        element.line = headerLine
        element.blockEnd = index
        let parentPath = Array(path.dropLast())
        let key = path[path.count - 1]
        try withTable(at: parentPath, createdAt: headerLine) { parent throws(TOMLError) in
            switch parent[key] {
            case nil:
                parent.set(key, .array([.table(element)]), line: headerLine)
            case .array(var items)?:
                guard items.allSatisfy({ $0.table != nil }) else {
                    throw TOMLError(line: headerLine, message: "'\(key)' is not an array of tables")
                }
                items.append(.table(element))
                parent.set(key, .array(items), line: headerLine)
            default:
                throw TOMLError(line: headerLine, message: "'\(key)' is already defined")
            }
        }
        definedTables = definedTables.filter { !$0.starts(with: path) || $0 == path }
        currentPath = path
    }

    private mutating func parseKeyValue() throws(TOMLError) {
        let keyLine = line
        let keyPath = try parseKey()
        skipSpaces()
        guard peek() == "=" else { throw fail("expected '=' after key") }
        advance()
        skipSpaces()
        let start = index
        let value = try parseValue()
        let range = start..<index
        let end = index
        let tablePath = currentPath + keyPath.dropLast()
        let key = keyPath[keyPath.count - 1]
        try withTable(at: tablePath, createdAt: keyLine) { table throws(TOMLError) in
            guard table[key] == nil else {
                throw TOMLError(line: keyLine, message: "'\(key)' is defined twice")
            }
            table.set(key, value, line: keyLine, valueRange: range)
        }
        try withTable(at: currentPath, createdAt: keyLine) { table throws(TOMLError) in table.blockEnd = end }
    }

    private mutating func withTable(
        at path: [String],
        createdAt createdLine: Int,
        _ body: (inout TOMLTable) throws(TOMLError) -> Void
    ) throws(TOMLError) {
        try Self.descend(&root, path[...], createdLine, body)
    }

    private static func descend(
        _ table: inout TOMLTable,
        _ path: ArraySlice<String>,
        _ createdLine: Int,
        _ body: (inout TOMLTable) throws(TOMLError) -> Void
    ) throws(TOMLError) {
        guard let key = path.first else {
            try body(&table)
            return
        }
        let rest = path.dropFirst()
        switch table[key] {
        case nil:
            var child = TOMLTable()
            child.line = createdLine
            try descend(&child, rest, createdLine, body)
            table.set(key, .table(child), line: createdLine)
        case .table(var child)?:
            if table.entry(key)?.valueRange != nil {
                throw TOMLError(line: createdLine, message: "inline table '\(key)' cannot be extended")
            }
            try descend(&child, rest, createdLine, body)
            table.modifyEntry(key) { entry in entry.value = .table(child) }
        case .array(var items)?:
            guard case .table(var last)? = items.last else {
                throw TOMLError(line: createdLine, message: "'\(key)' is not a table")
            }
            try descend(&last, rest, createdLine, body)
            items[items.count - 1] = .table(last)
            table.modifyEntry(key) { entry in entry.value = .array(items) }
        default:
            throw TOMLError(line: createdLine, message: "'\(key)' is not a table")
        }
    }

    private mutating func parseKey() throws(TOMLError) -> [String] {
        var parts: [String] = []
        while true {
            skipSpaces()
            parts.append(try parseSimpleKey())
            skipSpaces()
            guard peek() == "." else { return parts }
            advance()
        }
    }

    private mutating func parseSimpleKey() throws(TOMLError) -> String {
        switch peek() {
        case "\""?:
            return try parseBasicString()
        case "'"?:
            return try parseLiteralString()
        default:
            var key = String.UnicodeScalarView()
            while let c = peek(), Self.isBareKeyScalar(c) {
                key.append(c)
                advance()
            }
            guard !key.isEmpty else { throw fail("expected a key") }
            return String(key)
        }
    }

    static func isBareKeyScalar(_ c: Unicode.Scalar) -> Bool {
        (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "_" || c == "-"
    }

    private mutating func parseValue() throws(TOMLError) -> TOMLValue {
        guard let c = peek() else { throw fail("expected a value") }
        switch c {
        case "\"":
            if peek(1) == "\"", peek(2) == "\"" { return .string(try parseMultilineBasicString()) }
            return .string(try parseBasicString())
        case "'":
            if peek(1) == "'", peek(2) == "'" { return .string(try parseMultilineLiteralString()) }
            return .string(try parseLiteralString())
        case "[":
            return try parseArray()
        case "{":
            return try parseInlineTable()
        case "t", "f":
            return try parseBool()
        default:
            return try parseNumberOrDate()
        }
    }

    private mutating func parseBool() throws(TOMLError) -> TOMLValue {
        for (word, value) in [("true", true), ("false", false)] where matches(word) {
            index += word.unicodeScalars.count
            return .bool(value)
        }
        throw fail("invalid value")
    }

    private func matches(_ word: String) -> Bool {
        for (offset, scalar) in word.unicodeScalars.enumerated() where peek(offset) != scalar {
            return false
        }
        return true
    }

    private mutating func parseBasicString() throws(TOMLError) -> String {
        advance()
        var result = String.UnicodeScalarView()
        while true {
            guard let c = peek(), c != "\n" else { throw fail("unterminated string") }
            advance()
            if c == "\"" { return String(result) }
            if c == "\\" {
                result.append(try parseEscape())
            } else {
                result.append(c)
            }
        }
    }

    private mutating func parseMultilineBasicString() throws(TOMLError) -> String {
        index += 3
        skipLeadingNewline()
        var result = String.UnicodeScalarView()
        while true {
            guard let c = peek() else { throw fail("unterminated multi-line string") }
            if c == "\"", peek(1) == "\"", peek(2) == "\"" {
                var quotes = 3
                while peek(quotes) == "\"", quotes < 5 { quotes += 1 }
                for _ in 0..<(quotes - 3) { result.append("\"") }
                index += quotes
                return String(result)
            }
            advance()
            if c == "\\" {
                if let next = peek(), next == " " || next == "\t" || next == "\n" || next == "\r" {
                    while let w = peek(), w == " " || w == "\t" || w == "\n" || w == "\r" { advance() }
                } else {
                    result.append(try parseEscape())
                }
            } else {
                result.append(c)
            }
        }
    }

    private mutating func parseLiteralString() throws(TOMLError) -> String {
        advance()
        var result = String.UnicodeScalarView()
        while true {
            guard let c = peek(), c != "\n" else { throw fail("unterminated string") }
            advance()
            if c == "'" { return String(result) }
            result.append(c)
        }
    }

    private mutating func parseMultilineLiteralString() throws(TOMLError) -> String {
        index += 3
        skipLeadingNewline()
        var result = String.UnicodeScalarView()
        while true {
            guard let c = peek() else { throw fail("unterminated multi-line string") }
            if c == "'", peek(1) == "'", peek(2) == "'" {
                var quotes = 3
                while peek(quotes) == "'", quotes < 5 { quotes += 1 }
                for _ in 0..<(quotes - 3) { result.append("'") }
                index += quotes
                return String(result)
            }
            advance()
            result.append(c)
        }
    }

    private mutating func skipLeadingNewline() {
        if peek() == "\r", peek(1) == "\n" { advance() }
        if peek() == "\n" { advance() }
    }

    private mutating func parseEscape() throws(TOMLError) -> Unicode.Scalar {
        guard let c = peek() else { throw fail("unterminated escape") }
        advance()
        switch c {
        case "b": return "\u{08}"
        case "t": return "\t"
        case "n": return "\n"
        case "f": return "\u{0C}"
        case "r": return "\r"
        case "e": return "\u{1B}"
        case "\"": return "\""
        case "\\": return "\\"
        case "x": return try parseHexEscape(length: 2)
        case "u": return try parseHexEscape(length: 4)
        case "U": return try parseHexEscape(length: 8)
        default: throw fail("invalid escape '\\\(c)'")
        }
    }

    private mutating func parseHexEscape(length: Int) throws(TOMLError) -> Unicode.Scalar {
        var digits = ""
        for _ in 0..<length {
            guard let c = peek(), c.properties.isASCIIHexDigit else { throw fail("invalid unicode escape") }
            digits.unicodeScalars.append(c)
            advance()
        }
        guard let value = UInt32(digits, radix: 16), let scalar = Unicode.Scalar(value) else {
            throw fail("invalid unicode escape")
        }
        return scalar
    }

    private mutating func parseArray() throws(TOMLError) -> TOMLValue {
        advance()
        var items: [TOMLValue] = []
        while true {
            skipWhitespaceInCollection()
            if peek() == "]" {
                advance()
                return .array(items)
            }
            items.append(try parseValue())
            skipWhitespaceInCollection()
            switch peek() {
            case ","?: advance()
            case "]"?: continue
            default: throw fail("expected ',' or ']' in array")
            }
        }
    }

    private mutating func parseInlineTable() throws(TOMLError) -> TOMLValue {
        let startLine = line
        advance()
        var table = TOMLTable()
        table.line = startLine
        while true {
            skipWhitespaceInCollection()
            if peek() == "}" {
                advance()
                return .table(table)
            }
            let keyLine = line
            let keyPath = try parseKey()
            skipSpaces()
            guard peek() == "=" else { throw fail("expected '=' in inline table") }
            advance()
            skipSpaces()
            let value = try parseValue()
            try Self.insert(value, at: keyPath[...], line: keyLine, into: &table)
            skipWhitespaceInCollection()
            switch peek() {
            case ","?: advance()
            case "}"?: continue
            default: throw fail("expected ',' or '}' in inline table")
            }
        }
    }

    private static func insert(_ value: TOMLValue, at path: ArraySlice<String>, line: Int, into table: inout TOMLTable) throws(TOMLError) {
        let key = path[path.startIndex]
        if path.count == 1 {
            guard table[key] == nil else { throw TOMLError(line: line, message: "'\(key)' is defined twice") }
            table.set(key, value, line: line)
            return
        }
        var child: TOMLTable
        switch table[key] {
        case nil: child = TOMLTable()
        case .table(let existing)?: child = existing
        default: throw TOMLError(line: line, message: "'\(key)' is not a table")
        }
        try insert(value, at: path.dropFirst(), line: line, into: &child)
        table.set(key, .table(child), line: line)
    }

    private mutating func parseNumberOrDate() throws(TOMLError) -> TOMLValue {
        var token = String.UnicodeScalarView()
        while let c = peek(), !Self.isValueTerminator(c) {
            token.append(c)
            advance()
        }
        if Self.looksLikeDate(token), peek() == " ", let d0 = peek(1), let d1 = peek(2), peek(3) == ":",
           d0.properties.numericType != nil, d1.properties.numericType != nil {
            token.append(" ")
            advance()
            while let c = peek(), !Self.isValueTerminator(c) {
                token.append(c)
                advance()
            }
        }
        let raw = String(token)
        guard !raw.isEmpty else { throw fail("expected a value") }
        if Self.looksLikeDate(token) || Self.looksLikeTime(token) { return .datetime(raw) }
        if let number = Self.number(from: raw) { return number }
        throw fail("invalid value '\(raw)'")
    }

    private static func isValueTerminator(_ c: Unicode.Scalar) -> Bool {
        c == " " || c == "\t" || c == "\n" || c == "\r" || c == "," || c == "]" || c == "}" || c == "#"
    }

    private static func looksLikeDate(_ token: String.UnicodeScalarView) -> Bool {
        let s = Array(token)
        return s.count >= 10 && s[4] == "-" && s[7] == "-" && s[0...3].allSatisfy { $0.properties.numericType != nil }
    }

    private static func looksLikeTime(_ token: String.UnicodeScalarView) -> Bool {
        let s = Array(token)
        return s.count >= 5 && s[2] == ":" && s[0...1].allSatisfy { $0.properties.numericType != nil }
    }

    private static func number(from raw: String) -> TOMLValue? {
        switch raw {
        case "inf", "+inf": return .float(.infinity)
        case "-inf": return .float(-.infinity)
        case "nan", "+nan", "-nan": return .float(.nan)
        default: break
        }
        if raw.hasPrefix("_") || raw.hasSuffix("_") || raw.contains("__") { return nil }
        let cleaned = raw.replacingOccurrences(of: "_", with: "")
        for (prefix, radix) in [("0x", 16), ("0o", 8), ("0b", 2)] where cleaned.hasPrefix(prefix) {
            return Int(cleaned.dropFirst(2), radix: radix).map { .integer($0) }
        }
        let isFloat = cleaned.contains(".") || cleaned.contains("e") || cleaned.contains("E")
        if isFloat {
            return Double(cleaned).map { .float($0) }
        }
        let digits = cleaned.hasPrefix("+") || cleaned.hasPrefix("-") ? cleaned.dropFirst() : Substring(cleaned)
        if digits.count > 1, digits.hasPrefix("0") { return nil }
        return Int(cleaned).map { .integer($0) }
    }
}
