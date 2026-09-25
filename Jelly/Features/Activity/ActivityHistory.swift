import JellyCore

struct ActivityHistory {
    static let capacity = 60

    private(set) var cpu: [Double] = []
    private(set) var memory: [Double] = []
    private(set) var received: [Double] = []
    private(set) var sent: [Double] = []

    mutating func append(_ system: SystemActivity) {
        guard let usage = system.cpu else { return }
        Self.push(usage, onto: &cpu)
        Self.push(system.memoryFraction, onto: &memory)
        Self.push(system.received ?? 0, onto: &received)
        Self.push(system.sent ?? 0, onto: &sent)
    }

    private static func push(_ value: Double, onto series: inout [Double]) {
        series.append(value)
        if series.count > capacity { series.removeFirst(series.count - capacity) }
    }
}
