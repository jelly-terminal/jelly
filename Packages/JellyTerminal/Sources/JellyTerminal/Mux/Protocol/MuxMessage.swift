enum MuxMessage: UInt8, Sendable {
    case hello = 1
    case open
    case opened
    case missing
    case output
    case input
    case resize
    case exited
    case terminate
    case prune
    case endAll
}
