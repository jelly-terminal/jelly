public struct PaneActivity: Equatable, Sendable, Identifiable {
    public var paneID: PaneID
    public var processes: [ProcessActivity]
    public var foreground: ProcessActivity?

    public var id: PaneID { paneID }

    public init(paneID: PaneID, processes: [ProcessActivity], foreground: ProcessActivity?) {
        self.paneID = paneID
        self.processes = processes
        self.foreground = foreground
    }

    public var shell: ProcessActivity? { processes.first }
    public var isIdle: Bool { foreground == nil }
    public var cpu: Double { processes.reduce(0) { $0 + $1.cpu } }
    public var memory: UInt64 { processes.reduce(0) { $0 + $1.memory } }
}
