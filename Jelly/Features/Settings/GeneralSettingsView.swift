import AppKit
import JellyCore
import SwiftUI

struct GeneralSettingsView: View {
    let configStore: ConfigStore

    @State private var program = ""
    @State private var recorder = ShortcutRecorder<Bool>()
    @FocusState private var isEditingProgram: Bool

    private enum DirectoryMode: Hashable {
        case inherit, home, custom
    }

    var body: some View {
        let settings = configStore.config.settings
        SettingsPage(configStore: configStore) {
            Form {
                Section {
                    Toggle("Ask before closing running processes", isOn: configStore.toggle(\.confirmQuit, at: "confirm-quit"))
                    Toggle("Keep sessions running after quitting", isOn: configStore.toggle(\.session.keepAlive, at: "session", "keep-alive"))
                }

                Section("Window") {
                    Toggle("Show sidebar on launch", isOn: configStore.toggle(\.window.sidebar, at: "window", "sidebar"))
                    Toggle("Show status bar", isOn: configStore.toggle(\.window.statusBar, at: "window", "status-bar"))
                }

                Section {
                    Toggle("Enable quick terminal", isOn: configStore.toggle(\.quickTerminal.enabled, at: "quick-terminal", "enabled"))
                    LabeledContent("Shortcut") {
                        Button {
                            if recorder.target == nil { recorder.start(true, onRecord: recordHotkey) } else { recorder.stop() }
                        } label: {
                            Text(recorder.target != nil ? "Type shortcut…" : settings.quickTerminal.hotkey?.symbols ?? "None")
                                .monospaced(recorder.target == nil && settings.quickTerminal.hotkey != nil)
                                .foregroundStyle(recorder.target != nil ? Color.accentColor : settings.quickTerminal.hotkey == nil ? .secondary : .primary)
                                .frame(width: Metrics.shortcutFieldWidth)
                        }
                        .buttonStyle(.bordered)
                    }
                    .disabled(!settings.quickTerminal.enabled)
                } header: {
                    Text("Quick Terminal")
                } footer: {
                    Text("Press the shortcut from any app to run commands in a small floating window. If ⌃Space switches input sources on your Mac, pick another shortcut or change it in System Settings → Keyboard → Keyboard Shortcuts.")
                }

                Section("New Tabs") {
                    Picker("Open in", selection: directoryMode) {
                        Text("Folder of the focused pane").tag(DirectoryMode.inherit)
                        Text("Home folder").tag(DirectoryMode.home)
                        Text("Custom folder").tag(DirectoryMode.custom)
                    }
                    if case .path(let path) = settings.shell.workingDirectory {
                        LabeledContent("Folder") {
                            HStack {
                                Text((path as NSString).abbreviatingWithTildeInPath)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(.secondary)
                                Button("Choose…", action: chooseFolder)
                            }
                        }
                    }
                    TextField("Shell", text: $program, prompt: Text("Login shell"))
                        .focused($isEditingProgram)
                        .onSubmit(saveProgram)
                        .onChange(of: isEditingProgram) { _, editing in if !editing { saveProgram() } }
                }

                Section {
                    Toggle("Share anonymous usage data", isOn: configStore.toggle(\.telemetry.enabled, at: "telemetry", "enabled"))
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Sends the app and macOS version with a random ID when \(AppInfo.name) opens and once a day. Nothing you type, run or see in a terminal is ever sent.")
                }
            }
        }
        .onAppear { program = settings.shell.program ?? "" }
        .onDisappear { recorder.stop() }
    }

    private var directoryMode: Binding<DirectoryMode> {
        Binding(
            get: {
                switch configStore.config.settings.shell.workingDirectory {
                case .inherit: .inherit
                case .home: .home
                case .path: .custom
                }
            },
            set: { mode in
                switch mode {
                case .inherit: configStore.set(.string("inherit"), at: ["settings", "shell", "working-directory"])
                case .home: configStore.set(.string("home"), at: ["settings", "shell", "working-directory"])
                case .custom: chooseFolder()
                }
            }
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        configStore.set(.string(url.path(percentEncoded: false)), at: ["settings", "shell", "working-directory"])
    }

    private func recordHotkey(_: Bool, _ chord: KeyChord?) {
        configStore.set(.string(chord?.description ?? "none"), at: ["settings", "quick-terminal", "hotkey"])
    }

    private func saveProgram() {
        let trimmed = program.trimmingCharacters(in: .whitespaces)
        guard trimmed != (configStore.config.settings.shell.program ?? "") else { return }
        if trimmed.isEmpty {
            configStore.remove(at: ["settings", "shell", "program"])
        } else {
            configStore.set(.string(trimmed), at: ["settings", "shell", "program"])
        }
    }
}
