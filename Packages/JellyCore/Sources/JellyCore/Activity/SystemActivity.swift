public struct SystemActivity: Equatable, Sendable {
    public var cpu: Double?
    public var memoryUsed: UInt64
    public var memoryTotal: UInt64
    public var received: Double?
    public var sent: Double?
    public var load: [Double]

    public init(cpu: Double?, memoryUsed: UInt64, memoryTotal: UInt64, received: Double?, sent: Double?, load: [Double]) {
        self.cpu = cpu
        self.memoryUsed = memoryUsed
        self.memoryTotal = memoryTotal
        self.received = received
        self.sent = sent
        self.load = load
    }

    public var memoryFraction: Double {
        memoryTotal == 0 ? 0 : Double(memoryUsed) / Double(memoryTotal)
    }
}
