import Foundation

struct MuxOpenRequest: Codable, Sendable {
    var pane: UUID
    var launch: ShellLaunch?
    var size: MuxWindowSize
    var scrollback: Int
}
