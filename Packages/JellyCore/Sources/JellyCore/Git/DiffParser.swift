public enum DiffParser {
    public static func parse(_ text: String) -> FileDiff {
        var diff = FileDiff()
        var oldLeft = 0
        var newLeft = 0
        var oldNumber = 0
        var newNumber = 0
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.last?.isEmpty == true { lines.removeLast() }
        for line in lines {
            if line.hasPrefix("\\") {
                if let hunk = diff.hunks.indices.last, let last = diff.hunks[hunk].lines.indices.last {
                    diff.hunks[hunk].lines[last].missingNewline = true
                }
                continue
            }
            guard oldLeft > 0 || newLeft > 0 else {
                if line.hasPrefix("@@ "), let hunk = hunk(from: line) {
                    diff.hunks.append(FileDiff.Hunk(header: String(line), oldStart: hunk.oldStart, newStart: hunk.newStart))
                    (oldLeft, newLeft) = (hunk.oldCount, hunk.newCount)
                    (oldNumber, newNumber) = (hunk.oldStart, hunk.newStart)
                } else if line.hasPrefix("Binary files ") || line == "GIT binary patch" {
                    diff.isBinary = true
                }
                continue
            }
            let body = String(line.dropFirst())
            let entry: FileDiff.Line
            switch line.first {
            case "+":
                entry = FileDiff.Line(kind: .added, text: body, newNumber: newNumber)
                newNumber += 1
                newLeft -= 1
            case "-":
                entry = FileDiff.Line(kind: .removed, text: body, oldNumber: oldNumber)
                oldNumber += 1
                oldLeft -= 1
            default:
                entry = FileDiff.Line(kind: .context, text: body, oldNumber: oldNumber, newNumber: newNumber)
                oldNumber += 1
                newNumber += 1
                oldLeft -= 1
                newLeft -= 1
            }
            diff.hunks[diff.hunks.count - 1].lines.append(entry)
        }
        return diff
    }

    private static func hunk(from line: Substring) -> (oldStart: Int, oldCount: Int, newStart: Int, newCount: Int)? {
        let ranges = line.dropFirst(3).prefix { $0 != "@" }.split(separator: " ")
        guard ranges.count == 2, ranges[0].hasPrefix("-"), ranges[1].hasPrefix("+"),
              let old = range(ranges[0].dropFirst()), let new = range(ranges[1].dropFirst())
        else { return nil }
        return (old.start, old.count, new.start, new.count)
    }

    private static func range(_ text: Substring) -> (start: Int, count: Int)? {
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        guard let start = Int(parts[0]) else { return nil }
        guard parts.count == 2 else { return (start, 1) }
        guard let count = Int(parts[1]) else { return nil }
        return (start, count)
    }
}
