import Darwin
import JellyCore
import JellyTerminal

struct AgentTracker {
    private var group: pid_t?
    private var provider: (any AgentProvider)?
    private var since: ContinuousClock.Instant?

    mutating func presence(
        of surface: TerminalSurface,
        catalog: AgentCatalog,
        now: ContinuousClock.Instant,
        idleAfter: Duration
    ) -> AgentPresence? {
        guard let foreground = surface.foregroundProcessGroup else {
            self = AgentTracker()
            return nil
        }
        if foreground != group || provider == nil {
            group = foreground
            provider = surface.processIdentity(of: foreground).flatMap(catalog.match)
            since = now
        }
        guard let provider, let since else { return nil }
        let state = provider.state(ofProcess: foreground)
            ?? AgentState.guessed(from: surface.activity, since: since, now: now, quietAfter: idleAfter)
        return AgentPresence(id: provider.id, name: provider.name, state: state)
    }
}
