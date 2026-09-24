import Darwin
import Dispatch
import Foundation

final class MuxChannel: @unchecked Sendable {
    let fd: Int32
    private var reader = MuxFrameReader()
    private var source: DispatchSourceRead?
    private let lock = NSLock()
    private var isClosed = false
    private var isSuspended = false
    private var isFinished = false
    private var readBuffer = [UInt8](repeating: 0, count: 64 * 1024)
    private var onFrame: (@Sendable (MuxFrame) -> Void)?
    private var onClose: (@Sendable () -> Void)?

    init(fd: Int32) {
        self.fd = fd
    }

    @discardableResult
    func send(_ frame: MuxFrame) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !isClosed else { return false }
        return MuxSocket.write(frame.encoded, to: fd)
    }

    func receive(timeout seconds: Int) -> MuxFrame? {
        MuxSocket.setReceiveTimeout(fd, seconds: seconds)
        defer { MuxSocket.setReceiveTimeout(fd, seconds: 0) }
        while true {
            do {
                if let frame = try reader.next() { return frame }
            } catch {
                return nil
            }
            let count = readBuffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
            if count < 0, errno == EINTR { continue }
            guard count > 0 else { return nil }
            reader.append(readBuffer[..<count])
        }
    }

    func handshake(timeout seconds: Int) -> Int? {
        guard send(MuxFrame(.hello, json: MuxHello(version: MuxProtocol.version))),
              let reply = receive(timeout: seconds),
              reply.message == .hello
        else { return nil }
        return reply.decode(MuxHello.self)?.version
    }

    func startReading(
        on queue: DispatchQueue,
        onFrame: @escaping @Sendable (MuxFrame) -> Void,
        onClose: @escaping @Sendable () -> Void
    ) {
        self.onFrame = onFrame
        self.onClose = onClose
        let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)
        source.setEventHandler { [weak self] in self?.readAvailable() }
        lock.lock()
        guard !isClosed else {
            lock.unlock()
            return
        }
        self.source = source
        lock.unlock()
        queue.async { [weak self] in self?.drainFrames() }
        source.resume()
    }

    func suspendReading() {
        lock.lock()
        defer { lock.unlock() }
        guard let source, !isSuspended else { return }
        isSuspended = true
        source.suspend()
    }

    func resumeReading() {
        lock.lock()
        defer { lock.unlock() }
        guard let source, isSuspended else { return }
        isSuspended = false
        source.resume()
    }

    func close() {
        lock.lock()
        let wasClosed = isClosed
        isClosed = true
        let source = source
        let wasSuspended = isSuspended
        self.source = nil
        isSuspended = false
        lock.unlock()
        guard !wasClosed else { return }
        if let source {
            source.setCancelHandler { [fd] in Darwin.close(fd) }
            source.cancel()
            if wasSuspended { source.resume() }
        } else {
            Darwin.close(fd)
        }
    }

    private func readAvailable() {
        guard !isFinished else { return }
        let count = readBuffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, $0.count) }
        if count < 0, errno == EINTR || errno == EAGAIN { return }
        guard count > 0 else {
            finish()
            return
        }
        reader.append(readBuffer[..<count])
        drainFrames()
    }

    private func drainFrames() {
        while !isFinished {
            let frame: MuxFrame?
            do {
                frame = try reader.next()
            } catch {
                finish()
                return
            }
            guard let frame else { return }
            onFrame?(frame)
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        close()
        let onClose = onClose
        self.onFrame = nil
        self.onClose = nil
        onClose?()
    }
}
