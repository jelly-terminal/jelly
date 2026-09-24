import Darwin

@MainActor
protocol PaneProcess: AnyObject {
    var shellPid: pid_t { get }
    func send(_ data: ArraySlice<UInt8>)
    func resize(_ size: winsize)
    func terminate()
}
