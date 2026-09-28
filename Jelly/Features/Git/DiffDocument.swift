import JellyCore

nonisolated struct DiffDocument: Sendable {
    struct Row: Sendable {
        enum Kind: Sendable {
            case hunk, context, added, removed
        }

        let kind: Kind
        let text: String
        let oldNumber: Int?
        let newNumber: Int?
        let tokens: [SyntaxToken]
    }

    let rows: [Row]
    let hunkRows: [Int]
    let additions: Int
    let deletions: Int

    init(_ diff: FileDiff, language: SyntaxLanguage?) {
        let lines = diff.hunks.flatMap(\.lines)
        var tokens: [[SyntaxToken]] = []
        if let language, lines.count <= ViewerLoader.highlightLineLimit {
            let text = lines.map(\.text).joined(separator: "\n")
            tokens = SyntaxHighlighter.lines(of: text, tokens: SyntaxHighlighter.tokens(in: text, language: language))
        }
        var rows: [Row] = []
        var hunkRows: [Int] = []
        var lineIndex = 0
        for hunk in diff.hunks {
            hunkRows.append(rows.count)
            rows.append(Row(kind: .hunk, text: hunk.header, oldNumber: nil, newNumber: nil, tokens: []))
            for line in hunk.lines {
                let kind: Row.Kind = switch line.kind {
                case .context: .context
                case .added: .added
                case .removed: .removed
                }
                let lineTokens = tokens.indices.contains(lineIndex) ? tokens[lineIndex] : []
                rows.append(Row(kind: kind, text: line.text, oldNumber: line.oldNumber, newNumber: line.newNumber, tokens: lineTokens))
                lineIndex += 1
            }
        }
        self.rows = rows
        self.hunkRows = hunkRows
        additions = diff.additions
        deletions = diff.deletions
    }
}
