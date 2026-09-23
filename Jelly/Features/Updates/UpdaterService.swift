import Foundation
import JellyCore
import Sparkle

final class UpdaterService {
    private let controller: SPUStandardUpdaterController
    private(set) var isAvailable = false

    init() {
        controller = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
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
}
