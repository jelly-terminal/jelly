struct TableReader {
    let table: TOMLTable
    let path: String
    private(set) var diagnostics: [Diagnostic] = []
    private var consumed: Set<String> = []

    init(_ table: TOMLTable, path: String) {
        self.table = table
        self.path = path
    }

    private func name(_ key: String) -> String {
        path.isEmpty ? key : "\(path).\(key)"
    }

    mutating func report(_ key: String, _ message: String) {
        diagnostics.append(Diagnostic(line: table.line(of: key), message: "\(name(key)): \(message)"))
    }

    mutating func missing(_ key: String) {
        diagnostics.append(Diagnostic(line: table.line, message: "\(path): missing '\(key)'"))
    }

    mutating func raw(_ key: String) -> TOMLValue? {
        consumed.insert(key)
        return table[key]
    }

    mutating func string(_ key: String) -> String? {
        guard let value = raw(key) else { return nil }
        if case .string(let string) = value { return string }
        report(key, "expected a string, found \(value.typeName)")
        return nil
    }

    mutating func bool(_ key: String) -> Bool? {
        guard let value = raw(key) else { return nil }
        if case .bool(let bool) = value { return bool }
        report(key, "expected true or false, found \(value.typeName)")
        return nil
    }

    mutating func int(_ key: String, in range: ClosedRange<Int>) -> Int? {
        guard let value = raw(key) else { return nil }
        guard case .integer(let int) = value else {
            report(key, "expected an integer, found \(value.typeName)")
            return nil
        }
        guard range.contains(int) else {
            report(key, "must be between \(range.lowerBound) and \(range.upperBound)")
            return nil
        }
        return int
    }

    mutating func double(_ key: String, in range: ClosedRange<Double>) -> Double? {
        guard let value = raw(key) else { return nil }
        let number: Double
        switch value {
        case .integer(let int): number = Double(int)
        case .float(let double): number = double
        default:
            report(key, "expected a number, found \(value.typeName)")
            return nil
        }
        guard range.contains(number) else {
            report(key, "must be between \(range.lowerBound.formatted) and \(range.upperBound.formatted)")
            return nil
        }
        return number
    }

    mutating func strings(_ key: String) -> [String]? {
        guard let value = raw(key) else { return nil }
        if case .array(let items) = value {
            var result: [String] = []
            for item in items {
                guard case .string(let string) = item else {
                    report(key, "expected a list of strings")
                    return nil
                }
                result.append(string)
            }
            return result
        }
        report(key, "expected a list of strings, found \(value.typeName)")
        return nil
    }

    mutating func choice<T>(_ key: String, _ options: [String: T]) -> T? {
        guard let string = string(key) else { return nil }
        if let option = options[string] { return option }
        report(key, "expected one of \(options.keys.sorted().joined(separator: ", "))")
        return nil
    }

    mutating func table(_ key: String) -> TableReader? {
        guard let value = raw(key) else { return nil }
        guard case .table(let child) = value else {
            report(key, "expected a table, found \(value.typeName)")
            return nil
        }
        return TableReader(child, path: name(key))
    }

    mutating func merge(_ child: TableReader) {
        diagnostics += child.finished()
    }

    func finished() -> [Diagnostic] {
        let unknown = table.keys.filter { !consumed.contains($0) }.map {
            Diagnostic(line: table.line(of: $0), message: "unknown key '\(name($0))'")
        }
        return diagnostics + unknown
    }
}

private extension Double {
    var formatted: String {
        self == rounded() ? String(Int(self)) : String(self)
    }
}
