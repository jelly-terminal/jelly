import Darwin
import JellyCore

enum ProcessArguments {
    static func identity(of pid: pid_t) -> ProcessIdentity? {
        guard pid > 0 else { return nil }
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var bytes = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &bytes, &size, nil, 0) == 0 else { return nil }
        return parse(bytes[..<size])
    }

    static func parse(_ bytes: ArraySlice<UInt8>) -> ProcessIdentity? {
        guard bytes.count > 4 else { return nil }
        let start = bytes.startIndex
        let argc = Int(bytes[start]) | Int(bytes[start + 1]) << 8 | Int(bytes[start + 2]) << 16 | Int(bytes[start + 3]) << 24
        var index = start + 4
        guard let executable = string(in: bytes, from: &index) else { return nil }
        while index < bytes.endIndex, bytes[index] == 0 { index += 1 }
        var arguments: [String] = []
        while arguments.count < argc, let argument = string(in: bytes, from: &index) {
            arguments.append(argument)
        }
        var environment: [String: String] = [:]
        while index < bytes.endIndex, let entry = string(in: bytes, from: &index), !entry.isEmpty {
            guard let separator = entry.firstIndex(of: "=") else { continue }
            environment[String(entry[..<separator])] = String(entry[entry.index(after: separator)...])
        }
        return ProcessIdentity(executable: executable, arguments: arguments, environment: environment)
    }

    private static func string(in bytes: ArraySlice<UInt8>, from index: inout Int) -> String? {
        guard index < bytes.endIndex else { return nil }
        let end = bytes[index...].firstIndex(of: 0) ?? bytes.endIndex
        let value = String(decoding: bytes[index..<end], as: UTF8.self)
        index = min(end + 1, bytes.endIndex)
        return value
    }
}
