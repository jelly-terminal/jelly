import Foundation

public struct MarkdownDocument: Equatable, Sendable {
    public struct Heading: Equatable, Sendable, Identifiable {
        public var level: Int
        public var title: String
        public var anchor: String
        public var blockIndex: Int

        public var id: String { anchor }
    }

    public var blocks: [MarkdownBlock]
    public var outline: [Heading]

    public init(_ text: String) {
        blocks = MarkdownParser.parse(text)
        var used: [String: Int] = [:]
        outline = blocks.enumerated().compactMap { index, block in
            guard case .heading(let level, let text) = block else { return nil }
            let title = Self.plainText(text)
            let base = Self.anchor(for: title)
            let count = used[base, default: 0]
            used[base] = count + 1
            return Heading(level: level, title: title, anchor: count == 0 ? base : "\(base)-\(count)", blockIndex: index)
        }
    }

    public static func plainText(_ inline: String) -> String {
        let chars = Array(inline.replacing(/!?\[([^\]]*)\]\([^)]*\)/) { String($0.1) }.replacing("~~", with: ""))
        var result = ""
        for (index, char) in chars.enumerated() {
            if char == "*" || char == "`" { continue }
            if char == "_" {
                let before = index > 0 && chars[index - 1].isLetter || index > 0 && chars[index - 1].isNumber
                let after = index + 1 < chars.count && (chars[index + 1].isLetter || chars[index + 1].isNumber)
                if !(before && after) { continue }
            }
            result.append(char)
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    public static func anchor(for title: String) -> String {
        let lowered = title.lowercased()
        var result = ""
        for char in lowered {
            if char.isLetter || char.isNumber || char == "-" || char == "_" {
                result.append(char)
            } else if char == " " {
                result.append("-")
            }
        }
        return result
    }
}
