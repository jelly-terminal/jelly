public struct PaneRoot: Equatable, Sendable {
    public var paneID: PaneID
    public var shellPID: Int32

    public init(paneID: PaneID, shellPID: Int32) {
        self.paneID = paneID
        self.shellPID = shellPID
    }
}
