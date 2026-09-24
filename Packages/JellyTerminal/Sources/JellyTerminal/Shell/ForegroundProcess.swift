import Darwin

enum ForegroundProcess {
    static func group(ofShell pid: pid_t) -> pid_t? {
        guard pid > 0 else { return nil }
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        let group = pid_t(bitPattern: info.e_tpgid)
        return group > 0 && group != pid ? group : nil
    }
}
