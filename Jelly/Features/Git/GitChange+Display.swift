import JellyCore
import SwiftUI

extension GitChange {
    var letter: String { kind.letter }

    var name: String {
        (path as NSString).lastPathComponent
    }

    var folder: String {
        (path as NSString).deletingLastPathComponent
    }

    func color(in theme: Theme) -> Color {
        kind.color(in: theme)
    }
}

extension GitChange.Kind {
    var letter: String {
        switch self {
        case .added: "A"
        case .modified: "M"
        case .deleted: "D"
        case .renamed: "R"
        case .copied: "C"
        case .typeChanged: "T"
        case .untracked: "?"
        case .conflicted: "U"
        }
    }

    var prominence: Int {
        switch self {
        case .deleted: 0
        case .untracked: 1
        case .added, .copied: 2
        case .renamed: 3
        case .typeChanged: 4
        case .modified: 5
        case .conflicted: 6
        }
    }

    func color(in theme: Theme) -> Color {
        let palette = theme.palette
        return switch self {
        case .added, .untracked: Color(palette[2])
        case .modified: Color(palette[3])
        case .deleted, .conflicted: Color(palette[1])
        case .renamed, .copied: Color(palette[4])
        case .typeChanged: Color(palette[5])
        }
    }
}

extension GitChange.Area {
    var title: String {
        switch self {
        case .conflicted: "Conflicts"
        case .staged: "Staged"
        case .unstaged: "Changes"
        case .untracked: "Untracked"
        }
    }
}
