public protocol AgentProvider: Sendable {
    var id: String { get }
    var name: String { get }
    func matches(_ process: ProcessIdentity) -> Bool
    func state(ofProcess pid: Int32) -> AgentState?
}

extension AgentProvider {
    public func state(ofProcess pid: Int32) -> AgentState? { nil }
}
