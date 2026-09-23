import AppKit
import JellyCore

extension ConfigStore {
    func edit(_ transform: (String) throws -> String) {
        let current = currentConfigText()
        do {
            let updated = try transform(current)
            guard updated != current else { return }
            try FileManager.default.createDirectory(at: paths.directory, withIntermediateDirectories: true)
            try updated.write(to: paths.configFile, atomically: true, encoding: .utf8)
            editError = nil
            reload()
        } catch let error as TOMLError {
            editError = "jelly.toml has an error on line \(error.line). Fix it to change settings here."
        } catch {
            editError = "Couldn’t save jelly.toml: \(error.localizedDescription)"
        }
    }

    func set(_ value: TOMLValue, at path: [String]) {
        edit { source in
            var editor = TOMLEditor(source)
            try editor.set(value, at: path)
            return editor.source
        }
    }

    func remove(at path: [String]) {
        edit { source in
            var editor = TOMLEditor(source)
            try editor.remove(at: path)
            return editor.source
        }
    }

    func openThemesFolder() {
        try? FileManager.default.createDirectory(at: paths.themesDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.open(paths.themesDirectory)
    }
}
