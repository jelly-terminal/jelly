import Foundation

struct TerminalModes: Equatable {
    static let privateModes = [1, 5, 6, 7, 9, 25, 45, 66, 1000, 1002, 1003, 1004, 1005, 1006, 1007, 1015, 1016, 2004]
    static let ansiModes = [4, 20]
    static let privateModesOnByDefault: Set<Int> = [7, 25, 1007]

    var privateModes: [Int: Bool] = [:]
    var ansiModes: [Int: Bool] = [:]

    static var queries: [UInt8] {
        let cancel = "\u{18}"
        let privateQueries = privateModes.map { "\u{1B}[?\($0)$p" }.joined()
        let ansiQueries = ansiModes.map { "\u{1B}[\($0)$p" }.joined()
        return Array((cancel + privateQueries + ansiQueries).utf8)
    }

    static func parse(_ replies: [UInt8]) -> TerminalModes {
        var modes = TerminalModes()
        let text = String(decoding: replies, as: UTF8.self)
        for reply in text.split(separator: "\u{1B}[") {
            guard let end = reply.range(of: "$y") else { continue }
            var body = reply[..<end.lowerBound]
            let isPrivate = body.hasPrefix("?")
            if isPrivate { body = body.dropFirst() }
            let fields = body.split(separator: ";")
            guard fields.count == 2, let mode = Int(fields[0]), let value = Int(fields[1]) else { continue }
            let state: Bool? = switch value {
            case 1, 3: true
            case 2, 4: false
            default: nil
            }
            guard let state else { continue }
            if isPrivate {
                modes.privateModes[mode] = state
            } else {
                modes.ansiModes[mode] = state
            }
        }
        return modes
    }

    var isOriginMode: Bool {
        privateModes[6] == true
    }

    var restoreSequence: [UInt8] {
        var text = ""
        for mode in Self.privateModes {
            guard let isSet = privateModes[mode] else { continue }
            if isSet {
                text += "\u{1B}[?\(mode)h"
            } else if Self.privateModesOnByDefault.contains(mode) {
                text += "\u{1B}[?\(mode)l"
            }
        }
        for mode in Self.ansiModes where ansiModes[mode] == true {
            text += "\u{1B}[\(mode)h"
        }
        return Array(text.utf8)
    }
}
