import AppKit
import JellyTerminal

@main
enum Main {
    static let delegate = AppDelegate()

    static func main() {
        MuxServer.runIfRequested()
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
