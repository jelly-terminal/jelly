import JellyCore

struct AgentPresence: Equatable {
    let id: String
    let name: String
    let state: AgentState

    var tone: AgentTone {
        switch state {
        case .working: .working
        case .needsInput: .attention
        case .idle: .ready
        }
    }

    var label: String {
        switch state {
        case .working: "Working"
        case .idle: "Ready"
        case .needsInput(let reason): Self.label(forWaitingOn: reason)
        }
    }

    private static func label(forWaitingOn reason: String?) -> String {
        switch reason {
        case "permission prompt": "Needs permission"
        case "input needed": "Has a question"
        case "dialog open": "Waiting on a dialog"
        case "sandbox request": "Needs network access"
        case "goal proposal": "Proposed a goal"
        default: "Needs your input"
        }
    }
}
