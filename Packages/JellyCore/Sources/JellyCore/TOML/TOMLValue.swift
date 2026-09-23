public enum TOMLValue: Equatable, Sendable {
    case string(String)
    case integer(Int)
    case float(Double)
    case bool(Bool)
    case datetime(String)
    case array([TOMLValue])
    case table(TOMLTable)

    public var typeName: String {
        switch self {
        case .string: "string"
        case .integer: "integer"
        case .float: "float"
        case .bool: "boolean"
        case .datetime: "datetime"
        case .array: "array"
        case .table: "table"
        }
    }

    public var table: TOMLTable? {
        if case .table(let table) = self { table } else { nil }
    }
}
