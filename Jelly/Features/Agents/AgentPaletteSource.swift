import Foundation
import JellyCore

struct AgentPaletteSource: PaletteSource {
    let section = "Agents"

    func items(in window: WindowModel) -> [PaletteItem] {
        window.agentPanes.compactMap { location in
            guard let agent = location.pane.agent else { return nil }
            return PaletteItem(
                id: "agent:" + location.pane.id.rawValue.uuidString,
                title: agent.name,
                subtitle: "\(location.pane.isAgentFinishedUnseen ? "Done" : agent.label) · \(location.session.name) · \(location.tab.displayTitle)",
                symbol: "sparkle",
                keywords: ["Agent " + agent.name, agent.label]
            ) {
                window.reveal(location.pane.id)
            }
        }
    }
}
