import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class PaneModel: Identifiable {
    let surface: TerminalSurface
    private(set) var title = ""
    private(set) var directory: String?
    private(set) var gridSize = (cols: 0, rows: 0)
    private(set) var agent: AgentPresence?
    private(set) var isAgentFinishedUnseen = false

    @ObservationIgnored private var agentTracker = AgentTracker()

    init(surface: TerminalSurface) {
        self.surface = surface
        gridSize = surface.gridSize
        surface.onTitleChange = { [weak self] in self?.title = $0 }
        surface.onDirectoryChange = { [weak self] in self?.directory = $0 }
        surface.onGridSizeChange = { [weak self] cols, rows in self?.gridSize = (cols, rows) }
    }

    var id: PaneID { surface.paneID }

    func refreshAgent(catalog: AgentCatalog, now: ContinuousClock.Instant, idleAfter: Duration) {
        let presence = agentTracker.presence(of: surface, catalog: catalog, now: now, idleAfter: idleAfter)
        guard presence?.id != agent?.id || presence?.state != agent?.state else { return }
        agent = presence
        if presence?.state != .idle { isAgentFinishedUnseen = false }
    }

    func clearAgent() {
        agentTracker = AgentTracker()
        if agent != nil { agent = nil }
        isAgentFinishedUnseen = false
    }

    func markAgentFinished(seen: Bool) {
        if isAgentFinishedUnseen != !seen { isAgentFinishedUnseen = !seen }
    }

    var agentTone: AgentTone? {
        guard let agent else { return nil }
        return isAgentFinishedUnseen ? .finished : agent.tone
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        if let directory { return (directory as NSString).lastPathComponent }
        return "shell"
    }
}
