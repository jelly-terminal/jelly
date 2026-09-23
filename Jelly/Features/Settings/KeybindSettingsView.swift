import JellyCore
import SwiftUI

struct KeybindSettingsView: View {
    let configStore: ConfigStore

    @State private var query = ""
    @State private var recorder = ShortcutRecorder()
    @State private var notice: String?

    var body: some View {
        let keybinds = configStore.config.keybinds
        SettingsPage(configStore: configStore) {
            Form {
                Section {
                    HStack {
                        TextField("Search", text: $query, prompt: Text("Search actions or shortcuts"))
                        Button("Reset All") {
                            configStore.edit { try KeybindEditor.resetAll(in: $0) }
                            notice = nil
                        }
                        .disabled(keybinds == Keybinds.defaults)
                    }
                } footer: {
                    Text(notice ?? "Click a shortcut, then press the new keys. Esc cancels, ⌫ removes it.")
                }

                ForEach(KeyAction.Group.allCases, id: \.self) { group in
                    let actions = KeyAction.catalog.filter { $0.group == group && matches($0, keybinds: keybinds) }
                    if !actions.isEmpty {
                        Section(group.rawValue) {
                            ForEach(actions, id: \.self) { action in
                                row(action, keybinds: keybinds)
                            }
                        }
                    }
                }
            }
        }
        .onDisappear { recorder.stop() }
    }

    private func row(_ action: KeyAction, keybinds: Keybinds) -> some View {
        let chords = keybinds.chords(for: action)
        let isChanged = chords != Keybinds.defaults.chords(for: action)
        let isRecording = recorder.action == action
        return LabeledContent(action.title) {
            HStack(spacing: 6) {
                if isChanged {
                    Button {
                        configStore.edit { try KeybindEditor.reset(action, in: $0) }
                        notice = nil
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.borderless)
                    .help("Reset to \(Keybinds.defaults.chords(for: action).first?.symbols ?? "none")")
                }
                Button {
                    if isRecording { recorder.stop() } else { recorder.start(action, onRecord: record) }
                } label: {
                    Text(isRecording ? "Type shortcut…" : chords.first?.symbols ?? "None")
                        .monospaced(!isRecording && !chords.isEmpty)
                        .foregroundStyle(isRecording ? Color.accentColor : chords.isEmpty ? .secondary : .primary)
                        .frame(width: Metrics.shortcutFieldWidth)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func record(_ action: KeyAction, _ chord: KeyChord?) {
        let keybinds = configStore.config.keybinds
        if let chord, let previous = keybinds[chord], previous != action {
            notice = "\(chord.symbols) was taken from “\(previous.title)”."
        } else {
            notice = nil
        }
        configStore.edit { try KeybindEditor.bind(chord, to: action, in: $0) }
    }

    private func matches(_ action: KeyAction, keybinds: Keybinds) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        if action.title.localizedCaseInsensitiveContains(trimmed) { return true }
        return keybinds.chords(for: action).contains { $0.symbols.localizedCaseInsensitiveContains(trimmed) || $0.description.contains(trimmed.lowercased()) }
    }
}
