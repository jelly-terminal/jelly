import JellyCore
import SwiftUI

enum AgentTone: Equatable {
    case working
    case attention
    case finished
    case ready

    func color(_ theme: Theme) -> Color {
        switch self {
        case .working: Color(theme.accent)
        case .attention: Color(theme.palette[3])
        case .finished: Color(theme.palette[2])
        case .ready: Color(theme.foreground).opacity(0.45)
        }
    }

    static func summary(of tones: some Sequence<AgentTone>) -> AgentTone? {
        var best: AgentTone?
        for tone in tones where best.map({ tone.priority > $0.priority }) ?? true {
            best = tone
        }
        return best
    }

    private var priority: Int {
        switch self {
        case .attention: 3
        case .finished: 2
        case .working: 1
        case .ready: 0
        }
    }
}
