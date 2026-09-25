public struct ActivitySnapshot: Equatable, Sendable {
    public var panes: [PaneActivity]
    public var others: [ProcessActivity]
    public var ports: [ListeningPort]?
    public var system: SystemActivity

    public init(panes: [PaneActivity], others: [ProcessActivity], ports: [ListeningPort]?, system: SystemActivity) {
        self.panes = panes
        self.others = others
        self.ports = ports
        self.system = system
    }
}
