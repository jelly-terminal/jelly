public enum GitStatusParser {
    public static func parse(_ output: String) -> GitStatus {
        var status = GitStatus()
        var records = output.split(separator: "\0")[...]
        while let record = records.popFirst() {
            if record.hasPrefix("# ") {
                readHeader(record.dropFirst(2), into: &status)
                continue
            }
            switch record.first {
            case "1":
                guard let (code, path) = fields(of: record, before: 8) else { continue }
                status.changes += changes(code: code, path: path, originalPath: nil)
            case "2":
                guard let (code, path) = fields(of: record, before: 9) else { continue }
                status.changes += changes(code: code, path: path, originalPath: records.popFirst().map(String.init))
            case "u":
                guard let (_, path) = fields(of: record, before: 10) else { continue }
                status.changes.append(GitChange(path: path, area: .conflicted, kind: .conflicted))
            case "?":
                status.changes.append(GitChange(path: String(record.dropFirst(2)), area: .untracked, kind: .untracked))
            default:
                continue
            }
        }
        return status
    }

    private static func readHeader(_ header: Substring, into status: inout GitStatus) {
        let parts = header.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return }
        let value = String(parts[1])
        switch parts[0] {
        case "branch.oid":
            status.commit = value == "(initial)" ? nil : value
        case "branch.head":
            status.branch = value == "(detached)" ? nil : value
        case "branch.upstream":
            status.upstream = value
        case "branch.ab":
            for count in value.split(separator: " ") {
                if count.hasPrefix("+") { status.ahead = Int(count.dropFirst()) ?? 0 }
                if count.hasPrefix("-") { status.behind = Int(count.dropFirst()) ?? 0 }
            }
        default:
            break
        }
    }

    private static func fields(of record: Substring, before count: Int) -> (code: Substring, path: String)? {
        let parts = record.split(separator: " ", maxSplits: count, omittingEmptySubsequences: false)
        guard parts.count == count + 1, parts[1].count == 2 else { return nil }
        return (parts[1], String(parts[count]))
    }

    private static func changes(code: Substring, path: String, originalPath: String?) -> [GitChange] {
        var result: [GitChange] = []
        if let kind = kind(code.first) {
            result.append(GitChange(path: path, originalPath: kind == .renamed || kind == .copied ? originalPath : nil, area: .staged, kind: kind))
        }
        if let kind = kind(code.last) {
            result.append(GitChange(path: path, area: .unstaged, kind: kind))
        }
        return result
    }

    private static func kind(_ code: Character?) -> GitChange.Kind? {
        switch code {
        case "M": .modified
        case "A": .added
        case "D": .deleted
        case "R": .renamed
        case "C": .copied
        case "T": .typeChanged
        default: nil
        }
    }
}
