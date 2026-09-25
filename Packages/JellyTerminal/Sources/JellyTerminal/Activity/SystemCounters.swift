import Darwin
import Foundation

struct SystemCounters {
    var cpuBusy: UInt64
    var cpuTotal: UInt64
    var memoryUsed: UInt64
    var memoryTotal: UInt64
    var received: UInt64
    var sent: UInt64
    var load: [Double]

    private static let host = mach_host_self()

    static func read() -> SystemCounters {
        let (busy, total) = cpuTicks()
        let (received, sent) = networkBytes()
        var load = [Double](repeating: 0, count: 3)
        if getloadavg(&load, 3) != 3 { load = [] }
        return SystemCounters(
            cpuBusy: busy,
            cpuTotal: total,
            memoryUsed: memoryUsed(),
            memoryTotal: ProcessInfo.processInfo.physicalMemory,
            received: received,
            sent: sent,
            load: load
        )
    }

    private static func cpuTicks() -> (busy: UInt64, total: UInt64) {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count) }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }
        let user = UInt64(info.cpu_ticks.0), system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2), nice = UInt64(info.cpu_ticks.3)
        return (user + system + nice, user + system + nice + idle)
    }

    private static func memoryUsed() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(host, HOST_VM_INFO64, $0, &count) }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let app = UInt64(stats.internal_page_count) - min(UInt64(stats.purgeable_count), UInt64(stats.internal_page_count))
        let pages = app + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return pages * UInt64(getpagesize())
    }

    private static func networkBytes() -> (received: UInt64, sent: UInt64) {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var size = 0
        guard sysctl(&mib, 6, nil, &size, nil, 0) == 0, size > 0 else { return (0, 0) }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 6, &buffer, &size, nil, 0) == 0 else { return (0, 0) }
        var received: UInt64 = 0, sent: UInt64 = 0
        buffer.withUnsafeBytes { raw in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= size {
                let header = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                guard header.ifm_msglen > 0 else { break }
                if Int32(header.ifm_type) == RTM_IFINFO2, offset + MemoryLayout<if_msghdr2>.size <= size {
                    let message = raw.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                    let flags = message.ifm_flags
                    if flags & IFF_UP != 0, flags & (IFF_LOOPBACK | IFF_POINTOPOINT) == 0 {
                        received &+= message.ifm_data.ifi_ibytes
                        sent &+= message.ifm_data.ifi_obytes
                    }
                }
                offset += Int(header.ifm_msglen)
            }
        }
        return (received, sent)
    }
}
