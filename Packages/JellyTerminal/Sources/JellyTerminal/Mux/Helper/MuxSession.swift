import Darwin
import Dispatch
import Foundation
import SwiftTerm

final class MuxSession: @unchecked Sendable {
    let id: UUID
    let queue = DispatchQueue(label: "jelly.mux.session", qos: .userInitiated)
    var onEnd: (@Sendable (UUID) -> Void)?

    private let launch: ShellLaunch
    private var size: MuxWindowSize
    private var process: LocalProcess!
    private let screen: HeadlessScreen
    private var client: MuxChannel?
    private var isEnded = false

    init(id: UUID, launch: ShellLaunch, size: MuxWindowSize, scrollback: Int) {
        self.id = id
        self.launch = launch
        self.size = size
        screen = HeadlessScreen(cols: Int(size.cols), rows: Int(size.rows), scrollback: scrollback)
        process = LocalProcess(delegate: self, dispatchQueue: queue)
        screen.onReply = { [weak self] reply in
            guard let self, self.client == nil else { return }
            self.process.send(data: reply)
        }
    }

    var isAttached: Bool {
        client != nil
    }

    func start() {
        process.startProcess(
            executable: launch.executable,
            args: launch.args,
            environment: launch.environment,
            execName: launch.argv0,
            currentDirectory: launch.directory
        )
    }

    func attach(_ channel: MuxChannel, size: MuxWindowSize, restored: Bool) {
        guard !isEnded else {
            channel.send(MuxFrame(.missing))
            channel.close()
            return
        }
        client?.close()
        client = nil
        resize(size)
        let opened = MuxOpened(pid: process.shellPid, restored: restored)
        guard channel.send(MuxFrame(.opened, json: opened)),
              !restored || channel.send(MuxFrame(.output, screen.snapshot()))
        else {
            channel.close()
            return
        }
        client = channel
        channel.startReading(
            on: queue,
            onFrame: { [weak self] frame in self?.handle(frame) },
            onClose: { [weak self, weak channel] in
                guard let self, let channel, self.client === channel else { return }
                self.client = nil
            }
        )
    }

    func terminate() {
        guard !isEnded else { return }
        let pid = process.shellPid
        if pid > 0 { kill(pid, SIGHUP) }
        process.terminate()
        ChildReaper.reap(pid)
        client?.close()
        client = nil
        end()
    }

    private func handle(_ frame: MuxFrame) {
        switch frame.message {
        case .input:
            process.send(data: frame.payload[...])
        case .resize:
            if let size = frame.decode(MuxWindowSize.self) { resize(size) }
        case .terminate:
            terminate()
        default:
            break
        }
    }

    private func resize(_ newSize: MuxWindowSize) {
        guard newSize != size else { return }
        size = newSize
        screen.resize(cols: Int(newSize.cols), rows: Int(newSize.rows))
        guard process.running, process.childfd >= 0 else { return }
        var windowSize = newSize.winsize
        _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &windowSize)
    }

    private func end() {
        guard !isEnded else { return }
        isEnded = true
        onEnd?(id)
    }
}

extension MuxSession: LocalProcessDelegate {
    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        client?.send(MuxFrame(.exited, json: MuxExit(code: exitCode)))
        client?.close()
        client = nil
        end()
    }

    func dataReceived(slice: ArraySlice<UInt8>) {
        screen.feed(slice)
        guard let client else { return }
        if !client.send(MuxFrame(.output, Array(slice))) {
            client.close()
            self.client = nil
        }
    }

    func getWindowSize() -> winsize {
        size.winsize
    }
}
