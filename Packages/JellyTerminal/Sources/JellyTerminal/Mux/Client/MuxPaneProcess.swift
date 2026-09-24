import Darwin
import Dispatch

@MainActor
final class MuxPaneProcess: PaneProcess {
    struct Connection: Sendable {
        let channel: MuxChannel
        let pid: pid_t
        let restored: Bool
    }

    let shellPid: pid_t
    private let channel: MuxChannel
    private let backlog: OutputBacklog
    private let writer = DispatchQueue(label: "jelly.mux.input", qos: .userInteractive)
    private weak var delegate: (any PaneProcessDelegate)?
    private var isFinished = false

    nonisolated static func connect(_ request: MuxOpenRequest, spawning: Bool) -> Connection? {
        for _ in 0..<2 {
            guard let channel = MuxClient.shared.connect(spawning: spawning) else { return nil }
            guard channel.send(MuxFrame(.open, json: request)), let reply = channel.receive(timeout: 5) else {
                channel.close()
                continue
            }
            guard reply.message == .opened, let opened = reply.decode(MuxOpened.self) else {
                channel.close()
                return nil
            }
            return Connection(channel: channel, pid: opened.pid, restored: opened.restored)
        }
        return nil
    }

    nonisolated static func discard(_ connection: Connection) {
        DispatchQueue.global(qos: .utility).async {
            connection.channel.send(MuxFrame(.terminate))
            connection.channel.close()
        }
    }

    init(connection: Connection, delegate: any PaneProcessDelegate) {
        shellPid = connection.pid
        channel = connection.channel
        backlog = OutputBacklog(channel: connection.channel)
        self.delegate = delegate
        let backlog = backlog
        channel.startReading(
            on: DispatchQueue(label: "jelly.mux.output", qos: .userInteractive),
            onFrame: { [weak self] frame in
                switch frame.message {
                case .output:
                    backlog.queued(frame.payload.count)
                    DispatchQueue.main.async { self?.received(frame.payload) }
                case .exited:
                    let code = frame.decode(MuxExit.self)?.code
                    DispatchQueue.main.async { self?.finished(code) }
                default:
                    break
                }
            },
            onClose: { [weak self] in
                DispatchQueue.main.async { self?.finished(nil) }
            }
        )
    }

    func send(_ data: ArraySlice<UInt8>) {
        let frame = MuxFrame(.input, Array(data))
        let channel = channel
        writer.async { channel.send(frame) }
    }

    func resize(_ size: winsize) {
        let frame = MuxFrame(.resize, json: MuxWindowSize(size))
        let channel = channel
        writer.async { channel.send(frame) }
    }

    func terminate() {
        guard !isFinished else { return }
        isFinished = true
        let channel = channel
        writer.async {
            channel.send(MuxFrame(.terminate))
            channel.close()
        }
    }

    private func received(_ bytes: [UInt8]) {
        backlog.delivered(bytes.count)
        guard !isFinished else { return }
        delegate?.paneProcess(didReceive: bytes[...])
    }

    private func finished(_ exitCode: Int32?) {
        guard !isFinished else { return }
        isFinished = true
        channel.close()
        delegate?.paneProcessDidExit(exitCode)
    }
}
