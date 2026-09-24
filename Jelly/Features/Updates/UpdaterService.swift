import Foundation
import JellyCore
import Observation
import Sparkle

@Observable
final class UpdaterService: NSObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    @ObservationIgnored private var controller: SPUStandardUpdaterController!
    private(set) var isAvailable = false
    private(set) var availableVersion: String?

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
        #if !DEBUG
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        if !key.isEmpty {
            controller.startUpdater()
            isAvailable = true
        }
        #endif
    }

    func apply(_ settings: UpdateSettings) {
        guard isAvailable else { return }
        controller.updater.automaticallyChecksForUpdates = settings.check
        controller.updater.automaticallyDownloadsUpdates = settings.autoInstall
    }

    func checkForUpdates() {
        guard isAvailable else { return }
        controller.checkForUpdates(nil)
    }

    nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        let version = item.displayVersionString
        Task { @MainActor in availableVersion = version }
    }

    nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in availableVersion = nil }
    }

    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        false
    }
}
