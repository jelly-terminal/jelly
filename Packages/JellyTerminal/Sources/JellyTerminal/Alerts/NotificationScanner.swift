import Darwin

struct NotificationScanner {
    private enum State {
        case ground
        case escape
        case osc
        case oscEscape
    }

    static let maxLength = 4096

    private var state = State.ground
    private var buffer: [UInt8] = []
    private var overflowed = false

    mutating func scan(_ bytes: ArraySlice<UInt8>) -> [String] {
        var messages: [String] = []
        var index = bytes.startIndex
        while index < bytes.endIndex {
            if state == .ground {
                guard let escape = Self.firstEscape(in: bytes[index...]) else { break }
                index = escape + 1
                state = .escape
                continue
            }
            let byte = bytes[index]
            index += 1
            switch state {
            case .ground:
                break
            case .escape:
                if byte == 0x5D {
                    state = .osc
                    buffer.removeAll(keepingCapacity: true)
                    overflowed = false
                } else {
                    state = byte == 0x1B ? .escape : .ground
                }
            case .osc:
                switch byte {
                case 0x07:
                    finish(into: &messages)
                case 0x1B:
                    state = .oscEscape
                case 0x18, 0x1A:
                    state = .ground
                default:
                    append(byte)
                }
            case .oscEscape:
                if byte == 0x5C {
                    finish(into: &messages)
                } else if byte == 0x5D {
                    state = .osc
                    buffer.removeAll(keepingCapacity: true)
                    overflowed = false
                } else {
                    state = byte == 0x1B ? .escape : .ground
                }
            }
        }
        return messages
    }

    private mutating func append(_ byte: UInt8) {
        guard !overflowed else { return }
        if buffer.count >= Self.maxLength {
            overflowed = true
            buffer.removeAll()
        } else {
            buffer.append(byte)
        }
    }

    private mutating func finish(into messages: inout [String]) {
        state = .ground
        guard !overflowed, let message = Self.notification(in: buffer) else { return }
        messages.append(message)
    }

    static func notification(in payload: [UInt8]) -> String? {
        guard let text = String(validating: payload, as: UTF8.self) else { return nil }
        let fields = text.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        guard fields.count == 2 else { return nil }
        let body = fields[1]
        switch fields[0] {
        case "9":
            let command = body.prefix { $0.isASCII && $0.isNumber }
            if !command.isEmpty, body.count == command.count || body.dropFirst(command.count).first == ";" { return nil }
            return body.isEmpty ? nil : String(body)
        case "777":
            let parts = body.split(separator: ";", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.first == "notify", parts.count >= 2 else { return nil }
            let title = String(parts[1])
            let message = parts.count == 3 ? String(parts[2]) : ""
            let joined = [title, message].filter { !$0.isEmpty }.joined(separator: ": ")
            return joined.isEmpty ? nil : joined
        default:
            return nil
        }
    }

    private static func firstEscape(in bytes: ArraySlice<UInt8>) -> Int? {
        bytes.withUnsafeBufferPointer { pointer -> Int? in
            guard let base = pointer.baseAddress,
                  let match = memchr(base, 0x1B, pointer.count)
            else { return nil }
            return bytes.startIndex + (UnsafeRawPointer(match) - UnsafeRawPointer(base))
        }
    }
}
