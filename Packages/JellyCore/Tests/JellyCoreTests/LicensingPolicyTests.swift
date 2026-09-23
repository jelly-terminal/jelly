import Foundation
import Testing
@testable import JellyCore

struct LicensingPolicyTests {
    let epoch = Date(timeIntervalSince1970: 0)

    @Test func freshTrialCountsDownFromFourteenDays() {
        let status = LicensingPolicy.status(license: nil, trialStartedAt: epoch, now: epoch)
        #expect(status == .trial(daysRemaining: 14))
    }

    @Test func trialExpiresAfterFourteenDays() {
        let almostDone = epoch.addingTimeInterval(LicensingPolicy.trialDuration - 60)
        #expect(LicensingPolicy.status(license: nil, trialStartedAt: epoch, now: almostDone) == .trial(daysRemaining: 1))

        let justOver = epoch.addingTimeInterval(LicensingPolicy.trialDuration + 1)
        #expect(LicensingPolicy.status(license: nil, trialStartedAt: epoch, now: justOver) == .trialExpired)
    }

    @Test func aLicenseOverridesTheTrialClock() {
        let license = License(key: "abc", email: "a@b.com", verifiedAt: epoch)
        let status = LicensingPolicy.status(license: license, trialStartedAt: epoch, now: epoch.addingTimeInterval(1_000_000))
        #expect(status == .licensed(license))
        #expect(status.allowsUsage)
        #expect(status.isLicensed)
    }
}
