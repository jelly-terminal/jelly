import Foundation

public enum MarkdownParser {
    public static func parse(_ text: String) -> [MarkdownBlock] {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { expandTabs(String($0)) }
        return parseBlocks(lines)
    }

    private struct Fence {
        let marker: Character
        let length: Int
        let indent: Int
        let language: String?
    }

    private struct ListMarker {
        let start: Int?
        let delimiter: Character
        let contentOffset: Int
    }

    private static func parseBlocks(_ lines: [String]) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if isBlank(line) {
                i += 1
            } else if indentation(line) >= 4 {
                blocks.append(indentedCode(lines, &i))
            } else if let fence = fenceOpening(line) {
                blocks.append(fencedCode(fence, lines, &i))
            } else if let heading = atxHeading(line) {
                blocks.append(heading)
                i += 1
            } else if isRule(line) {
                blocks.append(.rule)
                i += 1
            } else if quoteContent(line) != nil {
                blocks.append(quote(lines, &i))
            } else if let marker = listMarker(line) {
                blocks.append(list(marker, lines, &i))
            } else if isHTMLStart(line) {
                blocks.append(html(lines, &i))
            } else if let table = table(lines, &i) {
                blocks.append(table)
            } else {
                blocks.append(paragraph(lines, &i))
            }
        }
        return blocks
    }

    private static func indentedCode(_ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var body: [String] = []
        while i < lines.count, isBlank(lines[i]) || indentation(lines[i]) >= 4 {
            body.append(dropIndent(lines[i], 4))
            i += 1
        }
        while body.last.map(isBlank) == true { body.removeLast() }
        return .code(language: nil, text: body.joined(separator: "\n"))
    }

    private static func fencedCode(_ fence: Fence, _ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var body: [String] = []
        i += 1
        while i < lines.count {
            let line = lines[i]
            i += 1
            if isFenceClose(line, for: fence) { break }
            body.append(dropIndent(line, fence.indent))
        }
        return .code(language: fence.language, text: body.joined(separator: "\n"))
    }

    private static func quote(_ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var body: [String] = []
        while i < lines.count {
            let line = lines[i]
            if let content = quoteContent(line) {
                body.append(content)
            } else if !isBlank(line), let last = body.last, !isBlank(last), !startsBlock(line) {
                body.append(line)
            } else {
                break
            }
            i += 1
        }
        return .quote(parseBlocks(body))
    }

    private static func list(_ first: ListMarker, _ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var items: [MarkdownList.Item] = []
        while i < lines.count, let marker = listMarker(lines[i]),
              (marker.start == nil) == (first.start == nil), marker.delimiter == first.delimiter {
            var body = [String(lines[i].dropFirst(marker.contentOffset))]
            i += 1
            while i < lines.count {
                let line = lines[i]
                if isBlank(line) {
                    body.append("")
                } else if indentation(line) >= marker.contentOffset {
                    body.append(dropIndent(line, marker.contentOffset))
                } else if let last = body.last, !isBlank(last), !startsBlock(line), listMarker(line) == nil {
                    body.append(dropIndent(line, 3))
                } else {
                    break
                }
                i += 1
            }
            while body.last.map(isBlank) == true { body.removeLast() }
            let (checked, content) = taskState(body)
            items.append(MarkdownList.Item(checked: checked, blocks: parseBlocks(content)))
        }
        return .list(MarkdownList(start: first.start, items: items))
    }

    private static func html(_ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var body: [String] = []
        while i < lines.count, !isBlank(lines[i]) {
            body.append(lines[i])
            i += 1
        }
        return .html(body.joined(separator: "\n"))
    }

    private static func table(_ lines: [String], _ i: inout Int) -> MarkdownBlock? {
        guard i + 1 < lines.count, lines[i].contains("|"),
              let alignments = tableAlignments(lines[i + 1])
        else { return nil }
        let header = tableCells(lines[i])
        guard header.count == alignments.count else { return nil }
        i += 2
        var rows: [[String]] = []
        while i < lines.count, !isBlank(lines[i]), !startsBlock(lines[i]) {
            var cells = tableCells(lines[i])
            cells = Array(cells.prefix(alignments.count))
            cells += Array(repeating: "", count: alignments.count - cells.count)
            rows.append(cells)
            i += 1
        }
        return .table(MarkdownTable(alignments: alignments, header: header, rows: rows))
    }

    private static func paragraph(_ lines: [String], _ i: inout Int) -> MarkdownBlock {
        var parts = [trimLeading(lines[i])]
        i += 1
        while i < lines.count {
            let line = lines[i]
            if isBlank(line) { break }
            if let level = setextLevel(line) {
                i += 1
                return .heading(level: level, text: join(parts))
            }
            if startsBlock(line) { break }
            parts.append(trimLeading(line))
            i += 1
        }
        let text = join(parts)
        if let image = standaloneImage(text) { return image }
        return .paragraph(text)
    }

    private static func join(_ parts: [String]) -> String {
        var text = ""
        for (index, part) in parts.enumerated() {
            let isLast = index == parts.count - 1
            if isLast {
                text += trimTrailing(part)
            } else if part.hasSuffix("  ") {
                text += trimTrailing(part) + "\n"
            } else if part.hasSuffix("\\") {
                text += part.dropLast() + "\n"
            } else {
                text += trimTrailing(part) + " "
            }
        }
        return text
    }

    private static func standaloneImage(_ text: String) -> MarkdownBlock? {
        let pattern = /!\[([^\]]*)\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)/
        guard let match = text.wholeMatch(of: pattern) else { return nil }
        return .image(alt: String(match.1), source: String(match.2))
    }

    private static func startsBlock(_ line: String) -> Bool {
        guard indentation(line) < 4 else { return false }
        if fenceOpening(line) != nil || atxHeading(line) != nil || isRule(line) || quoteContent(line) != nil || isHTMLStart(line) {
            return true
        }
        guard let marker = listMarker(line) else { return false }
        return marker.start == nil || marker.start == 1
    }

    private static func fenceOpening(_ line: String) -> Fence? {
        let indent = indentation(line)
        guard indent < 4 else { return nil }
        let rest = line.dropFirst(indent)
        guard let marker = rest.first, marker == "`" || marker == "~" else { return nil }
        let length = rest.prefix { $0 == marker }.count
        guard length >= 3 else { return nil }
        let info = rest.dropFirst(length).trimmingCharacters(in: .whitespaces)
        if marker == "`", info.contains("`") { return nil }
        let language = info.split(separator: " ").first.map(String.init)
        return Fence(marker: marker, length: length, indent: indent, language: language)
    }

    private static func isFenceClose(_ line: String, for fence: Fence) -> Bool {
        guard indentation(line) < 4 else { return false }
        let rest = trimLeading(line)
        let length = rest.prefix { $0 == fence.marker }.count
        return length >= fence.length && rest.dropFirst(length).allSatisfy(\.isWhitespace)
    }

    private static func atxHeading(_ line: String) -> MarkdownBlock? {
        guard indentation(line) < 4 else { return nil }
        let rest = trimLeading(line)
        let level = rest.prefix { $0 == "#" }.count
        guard (1...6).contains(level) else { return nil }
        let after = rest.dropFirst(level)
        guard after.isEmpty || after.first == " " else { return nil }
        var text = after.trimmingCharacters(in: .whitespaces)
        let closing = text.reversed().prefix { $0 == "#" }.count
        if closing == text.count {
            text = ""
        } else if closing > 0, text.dropLast(closing).last == " " {
            text = String(text.dropLast(closing)).trimmingCharacters(in: .whitespaces)
        }
        return .heading(level: level, text: text)
    }

    private static func setextLevel(_ line: String) -> Int? {
        guard indentation(line) < 4 else { return nil }
        let text = line.trimmingCharacters(in: .whitespaces)
        guard let first = text.first, first == "=" || first == "-", text.allSatisfy({ $0 == first }) else { return nil }
        return first == "=" ? 1 : 2
    }

    private static func isRule(_ line: String) -> Bool {
        guard indentation(line) < 4 else { return false }
        let marks = line.filter { $0 != " " }
        guard let first = marks.first, "-*_".contains(first), marks.count >= 3 else { return false }
        return marks.allSatisfy { $0 == first }
    }

    private static func quoteContent(_ line: String) -> String? {
        guard indentation(line) < 4 else { return nil }
        let rest = trimLeading(line)
        guard rest.first == ">" else { return nil }
        let content = rest.dropFirst()
        return String(content.first == " " ? content.dropFirst() : content)
    }

    private static func listMarker(_ line: String) -> ListMarker? {
        let chars = Array(line)
        let indent = indentation(line)
        guard indent < 4, indent < chars.count else { return nil }
        var end = indent
        let start: Int?
        let delimiter: Character
        if "-*+".contains(chars[indent]) {
            start = nil
            delimiter = chars[indent]
            end += 1
        } else {
            let digits = chars[indent...].prefix { $0.isASCII && $0.isNumber }
            guard (1...9).contains(digits.count) else { return nil }
            end += digits.count
            guard end < chars.count, chars[end] == "." || chars[end] == ")" else { return nil }
            start = Int(String(digits))
            delimiter = chars[end]
            end += 1
        }
        if end == chars.count { return ListMarker(start: start, delimiter: delimiter, contentOffset: end + 1) }
        guard chars[end] == " " else { return nil }
        let spaces = chars[end...].prefix { $0 == " " }.count
        let isEmpty = end + spaces == chars.count
        let offset = isEmpty || spaces > 4 ? end + 1 : end + spaces
        return ListMarker(start: start, delimiter: delimiter, contentOffset: offset)
    }

    private static func taskState(_ body: [String]) -> (Bool?, [String]) {
        guard let first = body.first else { return (nil, body) }
        let states: [(String, Bool)] = [("[ ] ", false), ("[x] ", true), ("[X] ", true)]
        for (prefix, checked) in states where first.hasPrefix(prefix) {
            return (checked, [String(first.dropFirst(prefix.count))] + body.dropFirst())
        }
        return (nil, body)
    }

    private static func isHTMLStart(_ line: String) -> Bool {
        guard indentation(line) < 4 else { return false }
        let rest = trimLeading(line)
        guard rest.first == "<", let next = rest.dropFirst().first else { return false }
        return next.isLetter || next == "/" || next == "!"
    }

    private static func tableAlignments(_ line: String) -> [MarkdownTable.Alignment]? {
        guard line.contains("|") || line.contains("-") else { return nil }
        let cells = tableCells(line)
        guard !cells.isEmpty else { return nil }
        var alignments: [MarkdownTable.Alignment] = []
        for cell in cells {
            let leading = cell.hasPrefix(":")
            let trailing = cell.hasSuffix(":")
            let dashes = cell.dropFirst(leading ? 1 : 0).dropLast(trailing ? 1 : 0)
            guard !dashes.isEmpty, dashes.allSatisfy({ $0 == "-" }) else { return nil }
            alignments.append(leading && trailing ? .center : trailing ? .trailing : .leading)
        }
        return alignments
    }

    private static func tableCells(_ line: String) -> [String] {
        var text = line.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("|") { text.removeFirst() }
        if text.hasSuffix("|"), !text.hasSuffix("\\|") { text.removeLast() }
        var cells: [String] = []
        var current = ""
        var inCode = false
        var escaped = false
        for char in text {
            if escaped {
                if char != "|" { current.append("\\") }
                current.append(char)
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "`" {
                inCode.toggle()
                current.append(char)
            } else if char == "|", !inCode {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        if escaped { current.append("\\") }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private static func expandTabs(_ line: String) -> String {
        guard line.contains("\t") else { return line }
        var result = ""
        for char in line {
            if char == "\t" {
                result += String(repeating: " ", count: 4 - result.count % 4)
            } else {
                result.append(char)
            }
        }
        return result
    }

    private static func isBlank(_ line: String) -> Bool {
        line.allSatisfy(\.isWhitespace)
    }

    private static func indentation(_ line: String) -> Int {
        line.prefix { $0 == " " }.count
    }

    private static func dropIndent(_ line: String, _ count: Int) -> String {
        String(line.dropFirst(min(count, indentation(line))))
    }

    private static func trimLeading(_ line: String) -> String {
        String(line.drop { $0 == " " })
    }

    private static func trimTrailing(_ line: String) -> String {
        var text = line
        while text.last == " " { text.removeLast() }
        return text
    }
}
