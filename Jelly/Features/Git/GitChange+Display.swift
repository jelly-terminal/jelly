import JellyCore
import SwiftUI

extension GitChange {
    var letter: String {
        switch kind {
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

    var name: String {
        (path as NSString).lastPathComponent
    }

    var folder: String {
        (path as NSString).deletingLastPathComponent
    }

    func color(in theme: Theme) -> Color {
        let palette = theme.palette
        return switch kind {
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
