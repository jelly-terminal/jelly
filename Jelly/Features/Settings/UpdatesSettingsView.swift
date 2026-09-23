import JellyCore
import SwiftUI

struct UpdatesSettingsView: View {
    let configStore: ConfigStore
    let updatesAvailable: Bool
    let onCheckNow: () -> Void

    var body: some View {
        SettingsPage(configStore: configStore) {
            Form {
                Section {
                    Toggle("Check for updates automatically", isOn: configStore.toggle(\.updates.check, at: "updates", "check"))
                    Toggle("Download and install updates automatically", isOn: configStore.toggle(\.updates.autoInstall, at: "updates", "auto-install"))
                        .disabled(!configStore.config.settings.updates.check)
                } footer: {
                    if !updatesAvailable {
                        Text("Updates are turned off in this build.")
                    }
                }

                Section {
                    LabeledContent("\(AppInfo.name) \(AppInfo.version)") {
                        Button("Check Now", action: onCheckNow)
                            .disabled(!updatesAvailable)
                    }
                }
            }
        }
    }
}
