import Foundation

enum ActivityFormat {
    private static let memoryStyle = ByteCountFormatStyle(style: .memory, allowedUnits: [.mb, .gb, .tb], spellsOutZero: false)
    private static let rateStyle = ByteCountFormatStyle(style: .decimal, allowedUnits: [.kb, .mb, .gb], spellsOutZero: false)

    static func cpu(_ percent: Double) -> String {
        percent >= 10 ? "\(Int(percent.rounded()))%" : String(format: "%.1f%%", percent)
    }

    static func fraction(_ fraction: Double?) -> String {
        fraction.map { "\(Int(($0 * 100).rounded()))%" } ?? "—"
    }

    static func bytes(_ bytes: UInt64) -> String {
        Int64(clamping: bytes).formatted(memoryStyle)
    }

    static func rate(_ bytesPerSecond: Double?) -> String {
        guard let bytesPerSecond else { return "—" }
        return Int64(bytesPerSecond.rounded()).formatted(rateStyle) + "/s"
    }

    static func uptime(since start: Date, now: Date = .now) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        switch seconds {
        case ..<60: return "\(seconds)s"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86400: return "\(seconds / 3600)h"
        default: return "\(seconds / 86400)d"
        }
    }
}
