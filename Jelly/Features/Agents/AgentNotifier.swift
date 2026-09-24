import AppKit
import JellyCore
import UserNotifications

final class AgentNotifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AgentNotifier()

    var onOpen: ((PaneID) -> Void)?

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func post(title: String, subtitle: String, body: String, pane: PaneID, sound: Bool) {
        let identifier = pane.rawValue.uuidString
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.body = body
            content.threadIdentifier = identifier
            content.userInfo = [Self.paneKey: identifier]
            if sound { content.sound = .default }
            try? await center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
        }
    }

    func withdraw(pane: PaneID) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [pane.rawValue.uuidString])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let raw = response.notification.request.content.userInfo[Self.paneKey] as? String,
              let uuid = UUID(uuidString: raw)
        else { return }
        await MainActor.run {
            self.onOpen?(PaneID(uuid))
        }
    }

    private nonisolated static let paneKey = "pane"
}
