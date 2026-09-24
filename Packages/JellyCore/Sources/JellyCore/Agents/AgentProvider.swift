public protocol AgentProvider: Sendable {
    var id: String { get }
    var name: String { get }
    func matches(_ process: ProcessIdentity) -> Bool
    func state(of process: ProcessIdentity, pid: Int32) -> AgentState?
}

extension AgentProvider {
    public func state(of process: ProcessIdentity, pid: Int32) -> AgentState? { nil }
}
