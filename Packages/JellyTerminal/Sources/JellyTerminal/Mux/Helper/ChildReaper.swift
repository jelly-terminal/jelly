import Darwin
import Foundation

enum ChildReaper {
    static func reap(_ pid: pid_t) {
        guard pid > 0 else { return }
        Thread.detachNewThread {
            var status: Int32 = 0
            while waitpid(pid, &status, 0) < 0, errno == EINTR {}
        }
    }
}
