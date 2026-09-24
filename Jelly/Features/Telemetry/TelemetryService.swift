import Foundation
import JellyCore

final class TelemetryService {
    private static let endpoint = URL(string: "https://us.i.posthog.com/batch/")!
    private static let installIDKey = "telemetryInstallID"
    private static let lastActiveDayKey = "telemetryLastActiveDay"

    private let apiKey: String?
    private let defaults = UserDefaults.standard
    private var isEnabled = false
    private var hasSentLaunch = false
    private var activeCheck: Timer?

    init() {
        #if DEBUG
        apiKey = nil
        #else
        let key = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String ?? ""
        apiKey = key.isEmpty ? nil : key
        #endif
    }

    func apply(_ settings: TelemetrySettings) {
        let enabled = settings.enabled && apiKey != nil
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        activeCheck?.invalidate()
        activeCheck = nil
        guard enabled else { return }
        if !hasSentLaunch {
            hasSentLaunch = true
            capture("app_launched")
        }
        captureActiveDay()
        activeCheck = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.captureActiveDay() }
        }
    }

    private func captureActiveDay() {
        let today = Date.now.formatted(.iso8601.year().month().day())
        guard defaults.string(forKey: Self.lastActiveDayKey) != today else { return }
        defaults.set(today, forKey: Self.lastActiveDayKey)
        capture("app_active")
    }

    private func capture(_ event: String) {
        guard isEnabled, let apiKey else { return }
        let payload: [String: Any] = [
            "api_key": apiKey,
            "batch": [[
                "event": event,
                "distinct_id": installID,
                "timestamp": Date.now.formatted(.iso8601),
                "properties": properties,
            ]],
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        Task.detached { _ = try? await URLSession.shared.data(for: request) }
    }

    private var installID: String {
        if let id = defaults.string(forKey: Self.installIDKey) { return id }
        let id = UUID().uuidString.lowercased()
        defaults.set(id, forKey: Self.installIDKey)
        return id
    }

    private var properties: [String: Any] {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        return [
            "$lib": "jelly",
            "$process_person_profile": false,
            "$geoip_disable": true,
            "$os": "macOS",
            "$os_version": "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            "$app_version": AppInfo.version,
            "arch": Self.architecture,
            "locale": Locale.current.identifier,
        ]
    }

    private static var architecture: String {
        #if arch(arm64)
        "arm64"
        #else
        "x86_64"
        #endif
    }
}
