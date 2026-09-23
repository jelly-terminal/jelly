import Foundation
import JellyCore

struct PendingImport: Identifiable {
    let id = UUID()
    let url: URL
    let plan: ImportPlan
    var switchToTheme: Bool

    init(url: URL, configStore: ConfigStore) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        self.url = url
        plan = ConfigImporter.plan(
            importing: source,
            file: url.lastPathComponent,
            currentConfig: configStore.currentConfigText(),
            existingThemeIDs: Set(configStore.config.themes.keys)
        )
        switchToTheme = plan.settingChanges.isEmpty && plan.keybindChanges.isEmpty && !plan.themes.isEmpty
    }

    var themeToActivate: Theme? {
        switchToTheme ? plan.themes.first?.theme : nil
    }
}
