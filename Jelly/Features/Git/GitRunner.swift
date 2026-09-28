import Darwin
import Foundation

nonisolated enum GitRunner {
    static let outputLimit = 8_000_000
    static let timeout: TimeInterval = 10

    static let executable: URL? = {
        let fileManager = FileManager.default
        if let path = ["/opt/homebrew/bin/git", "/usr/local/bin/git"].first(where: fileManager.isExecutableFile) {
            return URL(filePath: path)
        }
        guard hasDeveloperTools else { return nil }
        return URL(filePath: "/usr/bin/git")
    }()

    @concurrent
    static func run(_ arguments: [String], in directory: URL, accepting codes: Set<Int32> = [0]) async -> Data? {
        guard let executable else { return nil }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: runBlocking(executable, arguments, in: directory, accepting: codes))
            }
        }
    }

    private static var hasDeveloperTools: Bool {
        runBlocking(URL(filePath: "/usr/bin/xcode-select"), ["-p"], in: URL(filePath: "/"), accepting: [0]) != nil
    }

    private static func runBlocking(_ executable: URL, _ arguments: [String], in directory: URL, accepting codes: Set<Int32>) -> Data? {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        var environment = ProcessInfo.processInfo.environment
        environment["GIT_OPTIONAL_LOCKS"] = "0"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        process.environment = environment
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        do { try process.run() } catch { return nil }
        let pid = process.processIdentifier
        let deadline = DispatchWorkItem { kill(pid, SIGKILL) }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: deadline)
        var data = Data()
        let handle = output.fileHandleForReading
        while let chunk = try? handle.read(upToCount: 1 << 16), !chunk.isEmpty {
            if data.count <= outputLimit { data.append(chunk.prefix(outputLimit + 1 - data.count)) }
        }
        process.waitUntilExit()
        deadline.cancel()
        guard process.terminationReason == .exit, codes.contains(process.terminationStatus) else { return nil }
        return data
    }
}
