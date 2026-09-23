public struct TOMLEditor {
    public private(set) var source: String

    public init(_ source: String) {
        self.source = source
    }

    public mutating func set(_ value: TOMLValue, at path: [String]) throws(TOMLError) {
        precondition(!path.isEmpty)
        let document = try TOMLParser.parse(source)
        let scalars = Array(source.unicodeScalars)

        var table = document
        var headerPath: [String] = []
        var header = document

        for (depth, key) in path.enumerated() {
            let isLeaf = depth == path.count - 1
            guard let entry = table.entry(key) else {
                insert(value, missing: Array(path[depth...]), under: headerPath, header: header, fullPath: path, scalars: scalars)
                return
            }
            if let range = entry.valueRange {
                let replacement: TOMLValue
                if isLeaf {
                    replacement = value
                } else {
                    replacement = .table(Self.merging(value, at: path[(depth + 1)...], into: entry.value.table ?? TOMLTable()))
                }
                replace(range, with: TOMLWriter.literal(replacement), scalars: scalars)
                return
            }
            guard !isLeaf, case .table(let child) = entry.value else { return }
            table = child
            if child.isHeaderDefined {
                headerPath = Array(path[...depth])
                header = child
            }
        }
    }

    public mutating func remove(at path: [String]) throws(TOMLError) {
        precondition(!path.isEmpty)
        let document = try TOMLParser.parse(source)
        let scalars = Array(source.unicodeScalars)
        var table = document
        for (depth, key) in path.enumerated() {
            guard let entry = table.entry(key) else { return }
            let isLeaf = depth == path.count - 1
            if let range = entry.valueRange {
                if isLeaf {
                    removeLine(containing: range, scalars: scalars)
                } else if depth == path.count - 2, case .table(let inline) = entry.value {
                    replace(range, with: TOMLWriter.literal(.table(inline.removing(path[depth + 1]))), scalars: scalars)
                }
                return
            }
            guard !isLeaf, case .table(let child) = entry.value else { return }
            table = child
        }
    }

    private mutating func removeLine(containing range: Range<Int>, scalars: [Unicode.Scalar]) {
        var start = range.lowerBound
        while start > 0, scalars[start - 1] != "\n" { start -= 1 }
        var end = range.upperBound
        while end < scalars.count, scalars[end] != "\n" { end += 1 }
        if end < scalars.count { end += 1 }
        replace(start..<end, with: "", scalars: scalars)
    }

    private static func merging(_ value: TOMLValue, at path: ArraySlice<String>, into table: TOMLTable) -> TOMLTable {
        var table = table
        let key = path[path.startIndex]
        if path.count == 1 {
            table.set(key, value)
        } else {
            table.set(key, .table(merging(value, at: path.dropFirst(), into: table[key]?.table ?? TOMLTable())))
        }
        return table
    }

    private mutating func replace(_ range: Range<Int>, with text: String, scalars: [Unicode.Scalar]) {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars[..<range.lowerBound])
        view.append(contentsOf: text.unicodeScalars)
        view.append(contentsOf: scalars[range.upperBound...])
        source = String(view)
    }

    private mutating func insert(
        _ value: TOMLValue,
        missing: [String],
        under headerPath: [String],
        header: TOMLTable,
        fullPath: [String],
        scalars: [Unicode.Scalar]
    ) {
        if headerPath.isEmpty, fullPath.count > 1 {
            var text = source
            if !text.isEmpty, !text.hasSuffix("\n") { text += "\n" }
            if !text.isEmpty { text += "\n" }
            text += "[\(TOMLWriter.keyPath(Array(fullPath.dropLast())))]\n"
            text += "\(TOMLWriter.key(fullPath[fullPath.count - 1])) = \(TOMLWriter.literal(value))\n"
            source = text
            return
        }
        let line = "\(TOMLWriter.keyPath(missing)) = \(TOMLWriter.literal(value))"
        guard let blockEnd = header.blockEnd else {
            source = line + "\n" + source
            return
        }
        var position = blockEnd
        while position < scalars.count, scalars[position] != "\n" { position += 1 }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars[..<position])
        view.append("\n")
        view.append(contentsOf: line.unicodeScalars)
        if position == scalars.count { view.append("\n") }
        view.append(contentsOf: scalars[position...])
        source = String(view)
    }
}
