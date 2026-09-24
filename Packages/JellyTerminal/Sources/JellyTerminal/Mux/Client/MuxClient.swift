import Darwin
import Foundation
import JellyCore

public final class MuxClient: @unchecked Sendable {
    public static let shared = MuxClient(
        socketPath: MuxProtocol.socketPath(bundleID: Bundle.main.bundleIdentifier ?? "com.monawwar.Jelly"),
        executable: Bundle.main.executablePath
    )

    private static let launchTimeout: TimeInterval = 3

    private let socketPath: String
    private let executable: String?
    private let launchLock = NSLock()
    private let stateLock = NSLock()
    private var isIncompatible = false

    init(socketPath: String, executable: String?) {
        self.socketPath = socketPath
        self.executable = executable
    }

    public func prune(keeping panes: Set<PaneID>) {
        let keep = panes.map(\.rawValue)
        DispatchQueue.global(qos: .utility).async {
            guard let channel = self.connect(spawning: false) else { return }
            channel.send(MuxFrame(.prune, json: MuxPrune(keep: keep)))
            channel.close()
        }
    }

    public func endAll() {
        guard let channel = connect(spawning: false) else { return }
        channel.send(MuxFrame(.endAll))
        channel.close()
    }

    func connect(spawning: Bool) -> MuxChannel? {
        if let channel = attempt() { return channel }
        guard spawning, let executable, !incompatible else { return nil }
        launchLock.lock()
        defer { launchLock.unlock() }
        if let channel = attempt() { return channel }
        guard !incompatible, MuxHelperLauncher.launch(executable: executable, socketPath: socketPath) else { return nil }
        let deadline = Date.now.addingTimeInterval(Self.launchTimeout)
        while Date.now < deadline {
            usleep(10_000)
            if let channel = attempt() { return channel }
            if incompatible { return nil }
        }
        return nil
    }

    private var incompatible: Bool {
        stateLock.withLock { isIncompatible }
    }

    private func attempt() -> MuxChannel? {
        guard let fd = MuxSocket.connect(to: socketPath) else { return nil }
        let channel = MuxChannel(fd: fd)
        guard let version = channel.handshake(timeout: 3) else {
            channel.close()
            return nil
        }
        guard MuxProtocol.supportedVersions.contains(version) else {
            stateLock.withLock { isIncompatible = true }
            channel.close()
            return nil
        }
        return channel
    }
}
