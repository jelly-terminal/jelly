import AppKit
import JellyCore
import JellyTerminal

final class AgentMonitor {
    private weak var window: WindowModel?
    private var timer: Timer?
    private var settings: AgentSettings?
    private var catalog = AgentCatalog(providers: [])

    init(window: WindowModel) {
        self.window = window
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    isolated deinit {
        timer?.invalidate()
    }

    private func tick() {
        guard let window else { return }
        let settings = window.configStore.settings.agents
        if settings != self.settings {
            self.settings = settings
            catalog = AgentCatalog(settings: settings)
            window.agentPanes.forEach { $0.pane.clearAgent() }
        }
        guard settings.enabled else { return }
        let now = ContinuousClock.now
        let idleAfter = Duration.seconds(settings.idleAfter)
        for location in window.agentPanes {
            let pane = location.pane
            let previous = pane.agent?.state
            pane.refreshAgent(catalog: catalog, now: now, idleAfter: idleAfter)
            let isShowing = window.isShowing(location)
            if isShowing, pane.isAgentFinishedUnseen { pane.markAgentFinished(seen: true) }
            guard let agent = pane.agent, agent.state != previous else { continue }
            switch agent.state {
            case .working:
                AgentNotifier.shared.withdraw(pane: pane.id)
            case .needsInput:
                notify("\(agent.name) \(agent.label.lowercased())", at: location, in: window, settings: settings)
            case .idle:
                guard previous == .working else { continue }
                pane.markAgentFinished(seen: isShowing)
                AgentNotifier.shared.withdraw(pane: pane.id)
                if settings.notifyFinished { notify("\(agent.name) is done", at: location, in: window, settings: settings) }
            }
        }
    }

    private func notify(_ title: String, at location: PaneLocation, in window: WindowModel, settings: AgentSettings) {
        switch settings.notify {
        case .never: return
        case .unfocused where window.isShowing(location): return
        case .unfocused, .always: break
        }
        AgentNotifier.shared.post(
            title: title,
            subtitle: "\(location.session.name) · \(location.tab.displayTitle)",
            body: location.pane.surface.workingDirectory.map { ($0 as NSString).abbreviatingWithTildeInPath } ?? "",
            pane: location.pane.id,
            sound: settings.notifySound
        )
    }
}
