import Foundation

final class OutputBacklog: @unchecked Sendable {
    private static let highWater = 4 << 20
    private static let lowWater = 1 << 20

    private let channel: MuxChannel
    private let lock = NSLock()
    private var bytes = 0
    private var isHolding = false

    init(channel: MuxChannel) {
        self.channel = channel
    }

    func queued(_ count: Int) {
        lock.withLock {
            bytes += count
            guard !isHolding, bytes > Self.highWater else { return }
            isHolding = true
            channel.suspendReading()
        }
    }

    func delivered(_ count: Int) {
        lock.withLock {
            bytes -= count
            guard isHolding, bytes < Self.lowWater else { return }
            isHolding = false
            channel.resumeReading()
        }
    }
}
