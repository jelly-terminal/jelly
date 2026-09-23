import Foundation
import JellyCore
import Observation

@Observable
final class LicenseService {
    private(set) var status: LicenseStatus
    var onChange: (() -> Void)?

    private let store: LicenseStore
    private let trial: TrialStore
    private let verifier: GumroadLicenseVerifier

    init(store: LicenseStore = .standard(), trial: TrialStore = .standard(), productPermalink: String = AppInfo.gumroadProductPermalink) {
        self.store = store
        self.trial = trial
        verifier = GumroadLicenseVerifier(productPermalink: productPermalink)
        let license = store.load()
        status = LicensingPolicy.status(license: license, trialStartedAt: trial.startedAt())
        if let license {
            Task { [weak self] in await self?.revalidate(license) }
        }
    }

    func activate(key: String) async -> String? {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter a license key." }
        do {
            let license = try await verifier.verify(key: trimmed)
            store.save(license)
            setStatus(.licensed(license))
            return nil
        } catch {
            return message(for: error)
        }
    }

    func deactivate() {
        store.clear()
        setStatus(LicensingPolicy.status(license: nil, trialStartedAt: trial.startedAt()))
    }

    private func revalidate(_ license: License) async {
        do {
            let refreshed = try await verifier.verify(key: license.key)
            store.save(refreshed)
            setStatus(.licensed(refreshed))
        } catch GumroadLicenseVerifier.VerifyError.refunded, GumroadLicenseVerifier.VerifyError.rejected {
            store.clear()
            setStatus(LicensingPolicy.status(license: nil, trialStartedAt: trial.startedAt()))
        } catch {
        }
    }

    private func message(for error: Error) -> String {
        guard let error = error as? GumroadLicenseVerifier.VerifyError else {
            return "Couldn't reach Gumroad. Check your connection and try again."
        }
        switch error {
        case .rejected(let message): return message
        case .refunded: return "This license was refunded and can't be activated."
        case .network: return "Couldn't reach Gumroad. Check your connection and try again."
        }
    }

    private func setStatus(_ newValue: LicenseStatus) {
        status = newValue
        onChange?()
    }
}
