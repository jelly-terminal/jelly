import AppKit
import Darwin
import SwiftUI

struct ProcessMenu: View {
    let pid: Int32
    let activity: ActivityModel
    var group: Int32?
    var onReveal: (() -> Void)?

    var body: some View {
        if let onReveal {
            Button("Show Pane", systemImage: "arrow.up.forward.square", action: onReveal)
            Divider()
        }
        if let group {
            Button("Interrupt", systemImage: "stop.circle") { activity.send(SIGINT, toGroup: group) }
            Button("Terminate", systemImage: "xmark.circle") { activity.send(SIGTERM, toGroup: group) }
            Button("Force Quit", systemImage: "exclamationmark.octagon") { activity.send(SIGKILL, toGroup: group) }
        } else {
            Button("Terminate", systemImage: "xmark.circle") { activity.send(SIGTERM, to: pid) }
            Button("Force Quit", systemImage: "exclamationmark.octagon") { activity.send(SIGKILL, to: pid) }
        }
        Divider()
        Button("Copy PID \(String(pid))", systemImage: "doc.on.doc") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(String(pid), forType: .string)
        }
    }
}
