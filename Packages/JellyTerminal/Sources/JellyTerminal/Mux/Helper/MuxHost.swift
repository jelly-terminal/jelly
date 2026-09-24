import Darwin
import Dispatch
import Foundation

final class MuxHost: @unchecked Sendable {
    private static let idleExitDelay: DispatchTimeInterval = .seconds(5)

    private let socketPath: String
    private let queue = DispatchQueue(label: "jelly.mux.host")
    private var sessions: [UUID: MuxSession] = [:]
    private var listener: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private var idleGeneration = 0

    init(socketPath: String) {
        self.socketPath = socketPath
    }

    func run() -> Never {
        signal(SIGPIPE, SIG_IGN)
        signal(SIGHUP, SIG_IGN)
        chdir("/")
        guard let fd = bindSocket() else { exit(0) }
        listener = fd
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in self?.acceptConnection() }
        acceptSource = source
        source.resume()
        queue.async { self.scheduleIdleExit() }
        dispatchMain()
    }

    private func bindSocket() -> Int32? {
        if let fd = try? MuxSocket.listen(at: socketPath) { return fd }
        if let running = MuxSocket.connect(to: socketPath) {
            close(running)
            return nil
        }
        unlink(socketPath)
        return try? MuxSocket.listen(at: socketPath)
    }

    private func acceptConnection() {
        guard let fd = MuxSocket.accept(from: listener) else { return }
        let channel = MuxChannel(fd: fd)
        DispatchQueue.global(qos: .userInitiated).async { self.serve(channel) }
    }

    private func serve(_ channel: MuxChannel) {
        guard let hello = channel.receive(timeout: 5), hello.message == .hello,
              channel.send(MuxFrame(.hello, json: MuxHello(version: MuxProtocol.version))),
              let request = channel.receive(timeout: 5)
        else {
            channel.close()
            return
        }
        switch request.message {
        case .open:
            guard let open = request.decode(MuxOpenRequest.self) else {
                channel.close()
                return
            }
            queue.async { self.open(open, on: channel) }
        case .prune:
            let keep = Set(request.decode(MuxPrune.self)?.keep ?? [])
            queue.async { self.prune(keeping: keep) }
            channel.close()
        case .endAll:
            queue.async { self.endAll() }
            channel.close()
        default:
            channel.close()
        }
    }

    private func open(_ request: MuxOpenRequest, on channel: MuxChannel) {
        if let session = sessions[request.pane] {
            session.queue.async { session.attach(channel, size: request.size, restored: true) }
            return
        }
        guard let launch = request.launch else {
            channel.send(MuxFrame(.missing))
            channel.close()
            return
        }
        let session = MuxSession(id: request.pane, launch: launch, size: request.size, scrollback: request.scrollback)
        session.onEnd = { [weak self] id in
            guard let self else { return }
            self.queue.async { self.sessionEnded(id) }
        }
        sessions[request.pane] = session
        session.queue.async {
            session.start()
            session.attach(channel, size: request.size, restored: false)
        }
    }

    private func prune(keeping keep: Set<UUID>) {
        for (id, session) in sessions where !keep.contains(id) {
            session.queue.async {
                if !session.isAttached { session.terminate() }
            }
        }
    }

    private func endAll() {
        for session in sessions.values {
            session.queue.async { session.terminate() }
        }
    }

    private func sessionEnded(_ id: UUID) {
        sessions[id] = nil
        scheduleIdleExit()
    }

    private func scheduleIdleExit() {
        guard sessions.isEmpty else { return }
        idleGeneration += 1
        let generation = idleGeneration
        queue.asyncAfter(deadline: .now() + Self.idleExitDelay) {
            guard generation == self.idleGeneration, self.sessions.isEmpty else { return }
            unlink(self.socketPath)
            exit(0)
        }
    }
}
