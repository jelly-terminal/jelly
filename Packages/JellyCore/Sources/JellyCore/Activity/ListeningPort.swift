public struct ListeningPort: Equatable, Sendable, Identifiable {
    public var port: UInt16
    public var pid: Int32
    public var command: String
    public var paneID: PaneID?
    public var isExposed: Bool

    public var id: UInt16 { port }

    public init(port: UInt16, pid: Int32, command: String, paneID: PaneID?, isExposed: Bool) {
        self.port = port
        self.pid = pid
        self.command = command
        self.paneID = paneID
        self.isExposed = isExposed
    }

    public var url: String { "http://localhost:\(port)" }
}
