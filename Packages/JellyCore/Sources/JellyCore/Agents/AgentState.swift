public enum AgentState: Equatable, Sendable {
    case working
    case needsInput(String?)
    case idle

    public static func guessed(
        from activity: TerminalActivity,
        since start: ContinuousClock.Instant,
        now: ContinuousClock.Instant,
        quietAfter quiet: Duration
    ) -> AgentState {
        let input = activity.lastInput.map { max($0, start) } ?? start
        if let alert = activity.lastAlert, alert >= start, alert > input {
            return .needsInput(activity.alertMessage)
        }
        let lastActivity = max(activity.lastOutput ?? start, input)
        return now - lastActivity >= quiet ? .idle : .working
    }
}
