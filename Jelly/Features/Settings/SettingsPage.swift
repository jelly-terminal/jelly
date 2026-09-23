import SwiftUI

struct SettingsPage<Content: View>: View {
    let configStore: ConfigStore
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            if let error = configStore.editError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metrics.settingsPadding)
                    .padding(.vertical, Metrics.settingsPadding / 2)
            }
            content
                .formStyle(.grouped)
            Divider()
            HStack {
                Text("Saved to jelly.toml as you change them.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Open jelly.toml", action: configStore.openConfigFile)
            }
            .padding(Metrics.settingsPadding)
        }
        .frame(width: Metrics.settingsWidth, height: Metrics.settingsHeight)
    }
}
