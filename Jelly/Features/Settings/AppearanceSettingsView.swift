import JellyCore
import JellyTerminal
import SwiftUI

struct AppearanceSettingsView: View {
    let configStore: ConfigStore
    let onImportTheme: () -> Void

    @State private var families: [String] = []
    @State private var opacity = 1.0
    @State private var blur = 0.0

    var body: some View {
        let settings = configStore.config.settings
        let themes = configStore.config.sortedThemes
        SettingsPage(configStore: configStore) {
            Form {
                Section {
                    Toggle("Match system appearance", isOn: followsSystem)
                    switch settings.theme {
                    case .fixed(let id):
                        themePicker("Theme", slot: .fixed, id: id, themes: themes)
                    case .adaptive(let light, let dark):
                        themePicker("Light", slot: .light, id: light, themes: themes)
                        themePicker("Dark", slot: .dark, id: dark, themes: themes)
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    HStack {
                        Text("\(themes.count) themes in your library.")
                        Spacer()
                        Button("Import Theme…", action: onImportTheme)
                        Button("Open Themes Folder", action: configStore.openThemesFolder)
                    }
                }

                Section("Font") {
                    Picker("Family", selection: configStore.binding(\.font.family, at: ["font", "family"], as: TOMLValue.string)) {
                        ForEach(familyOptions(current: settings.font.family), id: \.self) { family in
                            Text(family).tag(family)
                        }
                    }
                    Stepper(value: configStore.binding(\.font.size, at: ["font", "size"], as: TOMLValue.number), in: 6...72, step: 1) {
                        LabeledContent("Size", value: "\(settings.font.size.formatted()) pt")
                    }
                    Toggle("Ligatures", isOn: configStore.toggle(\.font.ligatures, at: "font", "ligatures"))
                    Toggle("Thicken strokes", isOn: configStore.toggle(\.font.thicken, at: "font", "thicken"))
                }

                Section("Window") {
                    LabeledContent("Background opacity") {
                        Slider(value: $opacity, in: 0.3...1, step: 0.05) { editing in
                            if !editing { configStore.set(.number(opacity), at: ["settings", "window", "background-opacity"]) }
                        }
                    }
                    LabeledContent("Blur") {
                        Slider(value: $blur, in: 0...60, step: 1) { editing in
                            if !editing { configStore.set(.integer(Int(blur)), at: ["settings", "window", "blur"]) }
                        }
                    }
                    .disabled(opacity >= 1)
                    Stepper(value: padding(\.paddingX), in: 0...40, step: 1) {
                        LabeledContent("Pane padding, sides", value: "\(Int(settings.window.paddingX)) pt")
                    }
                    Stepper(value: padding(\.paddingY), in: 0...40, step: 1) {
                        LabeledContent("Pane padding, bottom", value: "\(Int(settings.window.paddingY)) pt")
                    }
                }
            }
        }
        .onAppear {
            if families.isEmpty { families = FontCatalog.monospacedFamilies() }
            opacity = settings.window.backgroundOpacity
            blur = Double(settings.window.blur)
        }
    }

    @ViewBuilder
    private func themePicker(_ title: String, slot: ThemeSlot, id: String, themes: [Theme]) -> some View {
        Picker(title, selection: Binding(get: { id }, set: { select($0, for: slot) })) {
            if !themes.contains(where: { $0.id == id }) {
                Text("\(id) (missing)").tag(id)
            }
            ForEach(themes) { theme in
                Text(theme.name).tag(theme.id)
            }
        }
        if let theme = themes.first(where: { $0.id == id }) {
            ThemeSwatch(theme: theme)
        }
    }

    private var followsSystem: Binding<Bool> {
        Binding(
            get: {
                if case .adaptive = configStore.config.settings.theme { return true }
                return false
            },
            set: { adaptive in
                let current = configStore.theme
                if adaptive {
                    let light = current.appearance == .light ? current.id : BuiltinThemes.lightID
                    let dark = current.appearance == .dark ? current.id : BuiltinThemes.darkID
                    writeAdaptive(light: light, dark: dark)
                } else {
                    configStore.set(.string(current.id), at: ["settings", "theme"])
                }
            }
        )
    }

    private enum ThemeSlot {
        case fixed, light, dark
    }

    private func select(_ id: String, for slot: ThemeSlot) {
        switch (slot, configStore.config.settings.theme) {
        case (.light, .adaptive(_, let dark)): writeAdaptive(light: id, dark: dark)
        case (.dark, .adaptive(let light, _)): writeAdaptive(light: light, dark: id)
        default: configStore.set(.string(id), at: ["settings", "theme"])
        }
    }

    private func writeAdaptive(light: String, dark: String) {
        configStore.set(.inlineTable(["light": .string(light), "dark": .string(dark)]), at: ["settings", "theme"])
    }

    private func familyOptions(current: String) -> [String] {
        families.contains(current) || families.isEmpty ? (families.isEmpty ? [current] : families) : [current] + families
    }

    private func padding(_ keyPath: KeyPath<WindowSettings, Double>) -> Binding<Double> {
        Binding(
            get: { configStore.config.settings.window[keyPath: keyPath] },
            set: { value in
                var window = configStore.config.settings.window
                if keyPath == \WindowSettings.paddingX { window.paddingX = value } else { window.paddingY = value }
                configStore.set(
                    .inlineTable(["x": .number(window.paddingX), "y": .number(window.paddingY)]),
                    at: ["settings", "window", "padding"]
                )
            }
        )
    }
}
