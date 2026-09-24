struct MuxFrameReader {
    enum Failure: Error, Equatable {
        case unknownMessage(UInt8)
        case oversized(Int)
    }

    private var buffer: [UInt8] = []
    private var offset = 0

    mutating func append<Bytes: Collection>(_ bytes: Bytes) where Bytes.Element == UInt8 {
        if offset > 0, offset == buffer.count {
            buffer.removeAll(keepingCapacity: true)
            offset = 0
        }
        buffer.append(contentsOf: bytes)
    }

    mutating func next() throws(Failure) -> MuxFrame? {
        guard buffer.count - offset >= MuxFrame.headerSize else { return nil }
        let kind = buffer[offset]
        guard let message = MuxMessage(rawValue: kind) else { throw .unknownMessage(kind) }
        var length = 0
        for index in 0..<4 {
            length |= Int(buffer[offset + 1 + index]) << (8 * index)
        }
        guard length <= MuxFrame.maxPayload else { throw .oversized(length) }
        let start = offset + MuxFrame.headerSize
        guard buffer.count - start >= length else { return nil }
        let frame = MuxFrame(message, Array(buffer[start..<start + length]))
        offset = start + length
        if offset > 1 << 20 {
            buffer.removeFirst(offset)
            offset = 0
        }
        return frame
    }
}
