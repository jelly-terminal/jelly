import Foundation

public enum TOMLWriter {
    public static func literal(_ value: TOMLValue) -> String {
        switch value {
        case .string(let string): quoted(string)
        case .integer(let int): String(int)
        case .float(let double): float(double)
        case .bool(let bool): bool ? "true" : "false"
        case .datetime(let raw): raw
        case .array(let items): "[" + items.map(literal).joined(separator: ", ") + "]"
        case .table(let table): inlineTable(table)
        }
    }

    public static func key(_ key: String) -> String {
        !key.isEmpty && key.unicodeScalars.allSatisfy(TOMLParser.isBareKeyScalar) ? key : quoted(key)
    }

    public static func keyPath(_ path: [String]) -> String {
        path.map(key).joined(separator: ".")
    }

    public static func quoted(_ string: String) -> String {
        var out = "\""
        for scalar in string.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            case "\u{1B}": out += "\\e"
            case _ where scalar.value < 0x20 || scalar.value == 0x7F:
                out += "\\u" + String(format: "%04X", scalar.value)
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out + "\""
    }

    public static func tableBody(_ table: TOMLTable) -> String {
        table.keys.compactMap { name in
            table[name].map { "\(key(name)) = \(literal($0))\n" }
        }.joined()
    }

    private static func inlineTable(_ table: TOMLTable) -> String {
        guard !table.isEmpty else { return "{}" }
        let pairs = table.keys.compactMap { name in table[name].map { "\(key(name)) = \(literal($0))" } }
        return "{ " + pairs.joined(separator: ", ") + " }"
    }

    private static func float(_ value: Double) -> String {
        if value.isNaN { return "nan" }
        if value.isInfinite { return value > 0 ? "inf" : "-inf" }
        if value == value.rounded(), abs(value) < 1e15 { return String(format: "%.1f", value) }
        return String(value)
    }
}
