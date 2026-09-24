import Foundation

struct MuxFrame: Equatable, Sendable {
    static let headerSize = 5
    static let maxPayload = 64 << 20

    var message: MuxMessage
    var payload: [UInt8]

    init(_ message: MuxMessage, _ payload: [UInt8] = []) {
        self.message = message
        self.payload = payload
    }

    init<Value: Encodable>(_ message: MuxMessage, json value: Value) {
        self.init(message, (try? Array(JSONEncoder().encode(value))) ?? [])
    }

    func decode<Value: Decodable>(_ type: Value.Type) -> Value? {
        try? JSONDecoder().decode(type, from: Data(payload))
    }

    var encoded: [UInt8] {
        var bytes = [UInt8]()
        bytes.reserveCapacity(Self.headerSize + payload.count)
        bytes.append(message.rawValue)
        withUnsafeBytes(of: UInt32(payload.count).littleEndian) { bytes.append(contentsOf: $0) }
        bytes.append(contentsOf: payload)
        return bytes
    }
}
