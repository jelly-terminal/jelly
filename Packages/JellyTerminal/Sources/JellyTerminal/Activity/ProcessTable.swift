import Darwin
import Foundation
import JellyCore

enum ProcessTable {
    static func records() -> [ProcessRecord] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let count = pids.withUnsafeMutableBytes { proc_listallpids($0.baseAddress, Int32($0.count)) }
        guard count > 0 else { return [] }
        return pids.prefix(Int(count)).compactMap(record)
    }

    static func record(of pid: pid_t) -> ProcessRecord? {
        guard pid > 0 else { return nil }
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        var usage = rusage_info_v2()
        let result = withUnsafeMutablePointer(to: &usage) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(pid, RUSAGE_INFO_V2, $0) }
        }
        guard result == 0 else { return nil }
        return ProcessRecord(
            pid: pid,
            parent: Int32(bitPattern: info.pbi_ppid),
            terminalGroup: Int32(bitPattern: info.e_tpgid),
            name: name(of: info),
            cpuTime: MachTime.nanoseconds(usage.ri_user_time &+ usage.ri_system_time),
            memory: usage.ri_phys_footprint,
            started: Date(timeIntervalSince1970: TimeInterval(info.pbi_start_tvsec) + TimeInterval(info.pbi_start_tvusec) / 1_000_000)
        )
    }

    private static func name(of info: proc_bsdinfo) -> String {
        let long = withUnsafeBytes(of: info.pbi_name) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        if !long.isEmpty { return long }
        return withUnsafeBytes(of: info.pbi_comm) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
    }
}
