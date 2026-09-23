enum QueryResponder {
    private static let xtversionPrefix: [UInt8] = [0x1B, UInt8(ascii: "P"), UInt8(ascii: ">"), UInt8(ascii: "|")]
    private static let stringTerminator: [UInt8] = [0x1B, UInt8(ascii: "\\")]

    static func rewrite(_ data: ArraySlice<UInt8>, version: String) -> ArraySlice<UInt8> {
        guard data.starts(with: xtversionPrefix), data.suffix(2).elementsEqual(stringTerminator) else {
            return data
        }
        return ArraySlice(xtversionPrefix + Array("Jelly \(version)".utf8) + stringTerminator)
    }
}
