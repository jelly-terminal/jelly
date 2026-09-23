import JellyCore
import SwiftUI

struct TerminalSettingsView: View {
    let configStore: ConfigStore

    @State private var scrollback = 0
    @FocusState private var isEditingScrollback: Bool

    var body: some View {
        SettingsPage(configStore: configStore) {
            Form {
                Section("Cursor") {
                    Picker("Style", selection: configStore.binding(\.cursor.style, at: ["cursor", "style"]) { .string($0.rawValue) }) {
                        Text("Block").tag(CursorSettings.Style.block)
                        Text("Bar").tag(CursorSettings.Style.bar)
                        Text("Underline").tag(CursorSettings.Style.underline)
                    }
                    .pickerStyle(.segmented)
                    Toggle("Blink", isOn: configStore.toggle(\.cursor.blink, at: "cursor", "blink"))
                }

                Section {
                    TextField("Scrollback lines", value: $scrollback, format: .number)
                        .focused($isEditingScrollback)
                        .onSubmit(saveScrollback)
                        .onChange(of: isEditingScrollback) { _, editing in if !editing { saveScrollback() } }
                } footer: {
                    Text("Lines kept per pane, up to 1,000,000.")
                }

                Section("Clipboard") {
                    Toggle("Copy text when it’s selected", isOn: configStore.toggle(\.clipboard.copyOnSelect, at: "clipboard", "copy-on-select"))
                    Toggle("Let programs read the clipboard", isOn: configStore.toggle(\.clipboard.osc52Read, at: "clipboard", "osc52-read"))
                }
            }
        }
        .onAppear { scrollback = configStore.config.settings.scrollback }
    }

    private func saveScrollback() {
        scrollback = min(max(scrollback, 0), 1_000_000)
        guard scrollback != configStore.config.settings.scrollback else { return }
        configStore.set(.integer(scrollback), at: ["settings", "scrollback"])
    }
}
