import Foundation

public enum LicenseStatus: Sendable, Equatable {
    case trial(daysRemaining: Int)
    case trialExpired
    case licensed(License)

    public var allowsUsage: Bool {
        switch self {
        case .trial, .licensed: true
        case .trialExpired: false
        }
    }

    public var isLicensed: Bool {
        if case .licensed = self { true } else { false }
    }
}

public enum LicensingPolicy {
    public static let trialDuration: TimeInterval = 14 * 24 * 60 * 60

    public static func status(license: License?, trialStartedAt: Date, now: Date = Date()) -> LicenseStatus {
        if let license { return .licensed(license) }
        let elapsed = now.timeIntervalSince(trialStartedAt)
        guard elapsed < trialDuration else { return .trialExpired }
        let daysRemaining = Int(((trialDuration - elapsed) / 86400).rounded(.up))
        return .trial(daysRemaining: max(daysRemaining, 1))
    }
}
