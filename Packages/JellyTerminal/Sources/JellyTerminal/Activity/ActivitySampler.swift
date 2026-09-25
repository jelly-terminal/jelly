import Darwin
import Foundation
import JellyCore

public actor ActivitySampler {
    private struct Baseline {
        var cpuTime: UInt64
        var started: Date
    }

    private struct CommandKey: Hashable {
        var pid: Int32
        var started: Date
    }

    private static let minimumInterval = Duration.milliseconds(500)

    private var baselines: [Int32: Baseline] = [:]
    private var cpu: [Int32: Double] = [:]
    private var sampledAt: ContinuousClock.Instant?
    private var counters: SystemCounters?
    private var system: SystemActivity?
    private var commands: [CommandKey: String] = [:]

    public init() {}

    public func sample(panes roots: [PaneRoot], includePorts: Bool, otherLimit: Int) -> ActivitySnapshot {
        let now = ContinuousClock.now
        let records = ProcessTable.records()
        let elapsed = sampledAt.map { now - $0 }
        let refreshes = elapsed.map { $0 >= Self.minimumInterval } ?? true
        if refreshes { updateCPU(records, elapsed: elapsed) }
        if refreshes || system == nil {
            system = systemActivity(elapsed: elapsed)
            sampledAt = now
        }

        let byPID = Dictionary(records.map { ($0.pid, $0) }, uniquingKeysWith: { first, _ in first })
        let tree = ProcessTree(records: records)
        var owners: [Int32: PaneID] = [:]
        let panes = roots.map { root in
            let nodes = tree.descendants(of: root.shellPID)
            nodes.forEach { owners[$0.pid] = root.paneID }
            let processes = nodes.compactMap { node in byPID[node.pid].map { activity(of: $0, depth: node.depth) } }
            let group = byPID[root.shellPID]?.terminalGroup ?? 0
            let foreground = group > 0 && group != root.shellPID ? processes.first { $0.pid == group } ?? processes.dropFirst().first : nil
            return PaneActivity(paneID: root.paneID, processes: processes, foreground: foreground)
        }

        let others = records
            .filter { owners[$0.pid] == nil }
            .sorted { (cpu[$0.pid] ?? 0, $0.memory) > (cpu[$1.pid] ?? 0, $1.memory) }
            .prefix(otherLimit)
            .map { activity(of: $0, depth: 0) }

        let ports = includePorts ? listeningPorts(records, owners: owners) : nil
        let live = Set(records.map(\.pid))
        commands = commands.filter { live.contains($0.key.pid) }
        return ActivitySnapshot(panes: panes, others: others, ports: ports, system: system ?? systemActivity(elapsed: nil))
    }

    private func updateCPU(_ records: [ProcessRecord], elapsed: Duration?) {
        let seconds = elapsed.map { Double($0.components.seconds) + Double($0.components.attoseconds) / 1e18 } ?? 0
        var next: [Int32: Baseline] = [:]
        var usage: [Int32: Double] = [:]
        for record in records {
            next[record.pid] = Baseline(cpuTime: record.cpuTime, started: record.started)
            guard seconds > 0, let previous = baselines[record.pid], previous.started == record.started, record.cpuTime >= previous.cpuTime else { continue }
            usage[record.pid] = Double(record.cpuTime - previous.cpuTime) / 1e9 / seconds * 100
        }
        baselines = next
        cpu = usage
    }

    private func systemActivity(elapsed: Duration?) -> SystemActivity {
        let current = SystemCounters.read()
        defer { counters = current }
        guard let previous = counters, let elapsed else {
            return SystemActivity(cpu: nil, memoryUsed: current.memoryUsed, memoryTotal: current.memoryTotal, received: nil, sent: nil, load: current.load)
        }
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        let total = current.cpuTotal &- previous.cpuTotal
        let busy = current.cpuBusy &- previous.cpuBusy
        func rate(_ now: UInt64, _ before: UInt64) -> Double? {
            guard seconds > 0, now >= before else { return nil }
            return Double(now - before) / seconds
        }
        return SystemActivity(
            cpu: total > 0 && busy <= total ? Double(busy) / Double(total) : nil,
            memoryUsed: current.memoryUsed,
            memoryTotal: current.memoryTotal,
            received: rate(current.received, previous.received),
            sent: rate(current.sent, previous.sent),
            load: current.load
        )
    }

    private func activity(of record: ProcessRecord, depth: Int) -> ProcessActivity {
        ProcessActivity(
            pid: record.pid,
            name: record.name,
            command: command(of: record),
            cpu: cpu[record.pid] ?? 0,
            memory: record.memory,
            depth: depth,
            started: record.started
        )
    }

    private func command(of record: ProcessRecord) -> String {
        let key = CommandKey(pid: record.pid, started: record.started)
        if let cached = commands[key] { return cached }
        let identity = ProcessArguments.identity(of: record.pid)
        let summary = identity.flatMap { $0.executable.contains(".app/") ? nil : $0.summary }
        let command = summary.flatMap { $0.isEmpty ? nil : $0 } ?? record.name
        commands[key] = command
        return command
    }

    private func listeningPorts(_ records: [ProcessRecord], owners: [Int32: PaneID]) -> [ListeningPort] {
        let user = getuid()
        var ports: [UInt16: ListeningPort] = [:]
        for record in records {
            guard owners[record.pid] != nil || Self.owner(of: record.pid) == user else { continue }
            for listener in SocketTable.listeners(of: record.pid) {
                let paneID = owners[record.pid]
                if var existing = ports[listener.port] {
                    existing.isExposed = existing.isExposed || !listener.isLoopback
                    if existing.paneID == nil, paneID != nil {
                        existing.pid = record.pid
                        existing.paneID = paneID
                        existing.command = command(of: record)
                    }
                    ports[listener.port] = existing
                } else {
                    ports[listener.port] = ListeningPort(port: listener.port, pid: record.pid, command: command(of: record), paneID: paneID, isExposed: !listener.isLoopback)
                }
            }
        }
        return ports.values.sorted { ($0.paneID == nil ? 1 : 0, $0.port) < ($1.paneID == nil ? 1 : 0, $1.port) }
    }

    private static func owner(of pid: pid_t) -> uid_t? {
        var info = proc_bsdshortinfo()
        let size = Int32(MemoryLayout<proc_bsdshortinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, &info, size) == size else { return nil }
        return info.pbsi_uid
    }
}
