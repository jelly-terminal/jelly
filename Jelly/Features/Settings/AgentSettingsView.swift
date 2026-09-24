import JellyCore
import SwiftUI

struct AgentSettingsView: View {
    let configStore: ConfigStore

    var body: some View {
        let agents = configStore.config.settings.agents
        SettingsPage(configStore: configStore) {
            Form {
                Section {
                    Toggle("Watch for AI agents", isOn: configStore.toggle(\.agents.enabled, at: "agents", "enabled"))
                } footer: {
                    Text("Jelly notices coding agents running in a pane and shows on the tab, the pane and the session whether they’re working, need you, or are done.")
                }

                Group {
                    Section("Notifications") {
                        Picker("Notify me", selection: configStore.binding(\.agents.notify, at: ["agents", "notify"]) { .string($0.rawValue) }) {
                            Text("When I’m not looking at the pane").tag(AgentSettings.Notify.unfocused)
                            Text("Always").tag(AgentSettings.Notify.always)
                            Text("Never").tag(AgentSettings.Notify.never)
                        }
                        Toggle("When an agent finishes", isOn: configStore.toggle(\.agents.notifyFinished, at: "agents", "notify-finished"))
                            .disabled(agents.notify == .never)
                        Toggle("Play a sound", isOn: configStore.toggle(\.agents.notifySound, at: "agents", "notify-sound"))
                            .disabled(agents.notify == .never)
                    }

                    Section {
                        ForEach(AgentCatalog.builtIn, id: \.id) { agent in
                            Toggle(agent.name, isOn: watching(agent.id))
                        }
                        ForEach(agents.custom, id: \.name) { agent in
                            LabeledContent(agent.name, value: agent.commands.joined(separator: ", "))
                        }
                    } header: {
                        Text("Agents")
                    } footer: {
                        Text("Claude Code reports exactly what it’s doing. Other agents are guessed from their output: a bell or notification means they need you, and \(agents.idleAfter) seconds of quiet means they’re done. Add your own with `custom` under `[settings.agents]` in jelly.toml.")
                    }
                }
                .disabled(!agents.enabled)
            }
        }
    }

    private func watching(_ id: String) -> Binding<Bool> {
        Binding(
            get: { configStore.config.settings.agents.watch.contains(id) },
            set: { watch in
                var ids = configStore.config.settings.agents.watch.filter { $0 != id }
                if watch { ids.append(id) }
                if ids == AgentSettings().watch {
                    configStore.remove(at: ["settings", "agents", "watch"])
                } else {
                    configStore.set(.array(ids.map(TOMLValue.string)), at: ["settings", "agents", "watch"])
                }
            }
        )
    }
}
