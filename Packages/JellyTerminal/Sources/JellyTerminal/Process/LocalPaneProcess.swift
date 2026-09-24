import Darwin
import SwiftTerm

@MainActor
final class LocalPaneProcess: PaneProcess {
    private weak var delegate: (any PaneProcessDelegate)?
    private var process: LocalProcess!

    init(launch: ShellLaunch, delegate: any PaneProcessDelegate) {
        self.delegate = delegate
        process = LocalProcess(delegate: self)
        process.startProcess(
            executable: launch.executable,
            args: launch.args,
            environment: launch.environment,
            execName: launch.argv0,
            currentDirectory: launch.directory
        )
    }

    var shellPid: pid_t {
        process.shellPid
    }

    func send(_ data: ArraySlice<UInt8>) {
        process.send(data: data)
    }

    func resize(_ size: winsize) {
        guard process.running, process.childfd >= 0 else { return }
        var size = size
        _ = PseudoTerminalHelpers.setWinSize(masterPtyDescriptor: process.childfd, windowSize: &size)
    }

    func terminate() {
        if process.shellPid > 0 { kill(process.shellPid, SIGHUP) }
        process.terminate()
    }
}

extension LocalPaneProcess: @preconcurrency LocalProcessDelegate {
    func processTerminated(_ source: LocalProcess, exitCode: Int32?) {
        delegate?.paneProcessDidExit(exitCode)
    }

    func dataReceived(slice: ArraySlice<UInt8>) {
        delegate?.paneProcess(didReceive: slice)
    }

    func getWindowSize() -> winsize {
        delegate?.windowSize ?? winsize(ws_row: 24, ws_col: 80, ws_xpixel: 0, ws_ypixel: 0)
    }
}
