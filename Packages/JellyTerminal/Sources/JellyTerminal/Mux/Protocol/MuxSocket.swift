import Darwin

enum MuxSocket {
    enum Failure: Error {
        case pathTooLong
        case system(Int32)
    }

    static func listen(at path: String) throws -> Int32 {
        let fd = try open()
        do {
            try withAddress(path) { address, length in
                if bind(fd, address, length) != 0 { throw Failure.system(errno) }
            }
        } catch {
            close(fd)
            throw error
        }
        chmod(path, 0o600)
        guard Darwin.listen(fd, 64) == 0 else {
            let code = errno
            close(fd)
            throw Failure.system(code)
        }
        return fd
    }

    static func connect(to path: String) -> Int32? {
        guard let fd = try? open() else { return nil }
        let connected = (try? withAddress(path) { address, length in
            Darwin.connect(fd, address, length) == 0
        }) ?? false
        guard connected else {
            close(fd)
            return nil
        }
        return fd
    }

    static func accept(from listener: Int32) -> Int32? {
        let fd = Darwin.accept(listener, nil, nil)
        guard fd >= 0 else { return nil }
        configure(fd)
        var uid = uid_t()
        var gid = gid_t()
        guard getpeereid(fd, &uid, &gid) == 0, uid == getuid() else {
            close(fd)
            return nil
        }
        return fd
    }

    static func write(_ bytes: [UInt8], to fd: Int32) -> Bool {
        bytes.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let written = Darwin.write(fd, buffer.baseAddress! + offset, buffer.count - offset)
                if written < 0 {
                    if errno == EINTR || errno == EAGAIN { continue }
                    return false
                }
                offset += written
            }
            return true
        }
    }

    static func setReceiveTimeout(_ fd: Int32, seconds: Int) {
        var timeout = timeval(tv_sec: seconds, tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
    }

    private static func open() throws -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw Failure.system(errno) }
        configure(fd)
        return fd
    }

    private static func configure(_ fd: Int32) {
        _ = fcntl(fd, F_SETFD, FD_CLOEXEC)
        var on: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        var buffer: Int32 = 1 << 20
        setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &buffer, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &buffer, socklen_t(MemoryLayout<Int32>.size))
    }

    private static func withAddress<Result>(
        _ path: String,
        _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> Result
    ) throws -> Result {
        var address = sockaddr_un()
        let bytes = Array(path.utf8)
        guard bytes.count < MemoryLayout.size(ofValue: address.sun_path) else { throw Failure.pathTooLong }
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { raw in
            raw.copyBytes(from: bytes)
            raw[bytes.count] = 0
        }
        return try withUnsafePointer(to: &address) { pointer in
            try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
    }
}
