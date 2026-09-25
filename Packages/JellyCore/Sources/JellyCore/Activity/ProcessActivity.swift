import Foundation

public struct ProcessActivity: Equatable, Sendable, Identifiable {
    public var pid: Int32
    public var name: String
    public var command: String
    public var cpu: Double
    public var memory: UInt64
    public var depth: Int
    public var started: Date

    public var id: Int32 { pid }

    public init(pid: Int32, name: String, command: String, cpu: Double, memory: UInt64, depth: Int, started: Date) {
        self.pid = pid
        self.name = name
        self.command = command
        self.cpu = cpu
        self.memory = memory
        self.depth = depth
        self.started = started
    }
}
