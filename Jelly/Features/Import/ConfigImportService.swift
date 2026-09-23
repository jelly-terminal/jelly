import Foundation
import JellyCore

enum ConfigImportService {
    static func apply(_ pending: PendingImport, to store: ConfigStore) throws {
        let paths = store.paths
        try ConfigLoader.createConfigFileIfMissing(paths: paths)

        for item in pending.plan.themes {
            let contents = ConfigImporter.themeFileContents(item.table)
            try contents.write(to: paths.themeFile(id: item.theme.id), atomically: true, encoding: .utf8)
        }

        let current = store.currentConfigText()
        var updated = try ConfigImporter.apply(pending.plan, to: current)
        if let theme = pending.themeToActivate {
            var editor = TOMLEditor(updated)
            try editor.set(.string(theme.id), at: ["settings", "theme"])
            updated = editor.source
        }
        if updated != current {
            try updated.write(to: paths.configFile, atomically: true, encoding: .utf8)
        }
        store.reload()
    }
}
