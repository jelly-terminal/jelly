public struct ThemeColor: Equatable, Hashable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init?(hex: String) {
        guard hex.hasPrefix("#") else { return nil }
        let digits = Array(hex.dropFirst())
        guard digits.allSatisfy(\.isHexDigit) else { return nil }
        let expanded: [Character]
        switch digits.count {
        case 3: expanded = digits.flatMap { [$0, $0] } + ["f", "f"]
        case 6: expanded = digits + ["f", "f"]
        case 8: expanded = digits
        default: return nil
        }
        func byte(_ i: Int) -> UInt8 { UInt8(String(expanded[i...i + 1]), radix: 16)! }
        self.init(red: byte(0), green: byte(2), blue: byte(4), alpha: byte(6))
    }

    public var hex: String {
        let rgb = [red, green, blue].map { String($0, radix: 16).leftPadded(to: 2) }.joined()
        return "#" + rgb + (alpha == 255 ? "" : String(alpha, radix: 16).leftPadded(to: 2))
    }

    public var isDark: Bool {
        (0.2126 * Double(red) + 0.7152 * Double(green) + 0.0722 * Double(blue)) < 128
    }
}

private extension String {
    func leftPadded(to length: Int) -> String {
        String(repeating: "0", count: max(0, length - count)) + self
    }
}
