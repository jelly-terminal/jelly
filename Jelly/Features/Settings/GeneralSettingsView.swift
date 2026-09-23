import AppKit
import JellyCore
import SwiftUI

struct GeneralSettingsView: View {
    let configStore: ConfigStore
    let license: LicenseService

    @State private var program = ""
    @State private var isLicenseSheetPresented = false
    @State private var isConfirmingDeactivate = false
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
                }

                Section("Window") {
                    Toggle("Show sidebar on launch", isOn: configStore.toggle(\.window.sidebar, at: "window", "sidebar"))
                    Toggle("Show status bar", isOn: configStore.toggle(\.window.statusBar, at: "window", "status-bar"))
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

                Section("License") {
                    licenseSection
                }
            }
        }
        .onAppear { program = settings.shell.program ?? "" }
        .sheet(isPresented: $isLicenseSheetPresented) {
            LicenseSheet(
                license: license,
                cancelTitle: "Cancel",
                onActivated: { isLicenseSheetPresented = false },
                onDismiss: { isLicenseSheetPresented = false }
            )
        }
        .confirmationDialog("Deactivate this license on this Mac?", isPresented: $isConfirmingDeactivate) {
            Button("Deactivate", role: .destructive, action: license.deactivate)
        } message: {
            Text("You can activate it again later with the same key.")
        }
    }

    @ViewBuilder
    private var licenseSection: some View {
        switch license.status {
        case .licensed(let active):
            LabeledContent("Licensed to", value: active.email ?? "This Mac")
            LabeledContent("Key") {
                HStack {
                    Text("•••• " + active.key.suffix(8))
                        .monospaced()
                        .foregroundStyle(.secondary)
                    Button("Deactivate…") { isConfirmingDeactivate = true }
                }
            }
        case .trial(let daysRemaining):
            LabeledContent("Trial", value: daysRemaining == 1 ? "1 day left" : "\(daysRemaining) days left")
            licenseButtons
        case .trialExpired:
            LabeledContent("Trial", value: "Ended")
            licenseButtons
        }
    }

    private var licenseButtons: some View {
        HStack {
            Spacer()
            Button("Buy a License") { NSWorkspace.shared.open(AppInfo.gumroadProductURL) }
            Button("Enter License Key…") { isLicenseSheetPresented = true }
        }
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
