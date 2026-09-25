import Darwin

enum SocketTable {
    struct Listener: Equatable {
        var port: UInt16
        var isLoopback: Bool
    }

    static func listeners(of pid: pid_t) -> [Listener] {
        let bytes = proc_pidinfo(pid, PROC_PIDLISTFDS, 0, nil, 0)
        guard bytes > 0 else { return [] }
        let stride = MemoryLayout<proc_fdinfo>.stride
        var descriptors = [proc_fdinfo](repeating: proc_fdinfo(), count: Int(bytes) / stride + 8)
        let used = descriptors.withUnsafeMutableBytes { proc_pidinfo(pid, PROC_PIDLISTFDS, 0, $0.baseAddress, Int32($0.count)) }
        guard used > 0 else { return [] }
        return descriptors.prefix(Int(used) / stride).compactMap { descriptor in
            guard descriptor.proc_fdtype == UInt32(PROX_FDTYPE_SOCKET) else { return nil }
            return listener(pid: pid, descriptor: descriptor.proc_fd)
        }
    }

    private static func listener(pid: pid_t, descriptor: Int32) -> Listener? {
        var info = socket_fdinfo()
        let size = Int32(MemoryLayout<socket_fdinfo>.size)
        guard proc_pidfdinfo(pid, descriptor, PROC_PIDFDSOCKETINFO, &info, size) == size,
              info.psi.soi_kind == Int32(SOCKINFO_TCP)
        else { return nil }
        let tcp = info.psi.soi_proto.pri_tcp
        guard tcp.tcpsi_state == TSI_S_LISTEN else { return nil }
        let address = tcp.tcpsi_ini
        let port = UInt16(bigEndian: UInt16(truncatingIfNeeded: address.insi_lport))
        guard port > 0 else { return nil }
        return Listener(port: port, isLoopback: isLoopback(address))
    }

    private static func isLoopback(_ address: in_sockinfo) -> Bool {
        if address.insi_vflag & UInt8(INI_IPV4) != 0 {
            return UInt32(bigEndian: address.insi_laddr.ina_46.i46a_addr4.s_addr) >> 24 == 127
        }
        return withUnsafeBytes(of: address.insi_laddr.ina_6) { bytes in
            bytes.prefix(15).allSatisfy { $0 == 0 } && bytes[15] == 1
        }
    }
}
