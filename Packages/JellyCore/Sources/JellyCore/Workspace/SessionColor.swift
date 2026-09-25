public enum SessionColor: String, CaseIterable, Codable, Sendable {
    case blue
    case green
    case yellow
    case red
    case purple

    public static let `default` = SessionColor.blue

    public var name: String {
        rawValue.capitalized
    }

    public var paletteIndex: Int {
        switch self {
        case .red: 1
        case .green: 2
        case .yellow: 3
        case .blue: 4
        case .purple: 5
        }
    }

    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SessionColor(rawValue: raw) ?? .default
    }
}
