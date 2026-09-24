enum AlternateScreenScanner {
    private static let modes: [[UInt8]] = ["1049", "1047", "47"].map { Array($0.utf8) }

    static func enterOffset(in bytes: ArraySlice<UInt8>) -> ArraySlice<UInt8>.Index? {
        var index = bytes.startIndex
        while let escape = bytes[index...].firstIndex(of: 0x1B) {
            if isEnter(bytes[escape...]) { return escape }
            index = bytes.index(after: escape)
        }
        return nil
    }

    private static func isEnter(_ bytes: ArraySlice<UInt8>) -> Bool {
        guard bytes.starts(with: [0x1B, UInt8(ascii: "["), UInt8(ascii: "?")]) else { return false }
        let parameters = bytes.dropFirst(3)
        return modes.contains { mode in
            parameters.starts(with: mode) && parameters.dropFirst(mode.count).first == UInt8(ascii: "h")
        }
    }
}
