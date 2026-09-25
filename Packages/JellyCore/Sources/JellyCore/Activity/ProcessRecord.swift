import Foundation

public struct ProcessRecord: Equatable, Sendable {
    public var pid: Int32
    public var parent: Int32
    public var terminalGroup: Int32
    public var name: String
    public var cpuTime: UInt64
    public var memory: UInt64
    public var started: Date

    public init(pid: Int32, parent: Int32, terminalGroup: Int32 = 0, name: String, cpuTime: UInt64 = 0, memory: UInt64 = 0, started: Date = .distantPast) {
        self.pid = pid
        self.parent = parent
        self.terminalGroup = terminalGroup
        self.name = name
        self.cpuTime = cpuTime
        self.memory = memory
        self.started = started
    }
}
