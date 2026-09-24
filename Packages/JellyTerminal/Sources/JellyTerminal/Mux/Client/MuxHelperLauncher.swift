import Darwin
import Foundation

enum MuxHelperLauncher {
    static func launch(executable: String, socketPath: String) -> Bool {
        var attributes: posix_spawnattr_t?
        posix_spawnattr_init(&attributes)
        defer { posix_spawnattr_destroy(&attributes) }
        posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETSID | POSIX_SPAWN_CLOEXEC_DEFAULT))

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)
        defer { posix_spawn_file_actions_destroy(&actions) }
        posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0)
        posix_spawn_file_actions_addopen(&actions, 1, "/dev/null", O_WRONLY, 0)
        posix_spawn_file_actions_addopen(&actions, 2, "/dev/null", O_WRONLY, 0)

        let arguments = [MuxProtocol.helperName, MuxProtocol.helperArgument, socketPath]
        let environment = ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" }
        let argv = arguments.map { strdup($0) } + [nil]
        let envp = environment.map { strdup($0) } + [nil]
        defer {
            argv.forEach { free($0) }
            envp.forEach { free($0) }
        }

        var pid = pid_t()
        guard posix_spawn(&pid, executable, &actions, &attributes, argv, envp) == 0 else { return false }
        ChildReaper.reap(pid)
        return true
    }
}
