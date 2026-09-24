import Darwin

@MainActor
protocol PaneProcessDelegate: AnyObject {
    var windowSize: winsize { get }
    func paneProcess(didReceive data: ArraySlice<UInt8>)
    func paneProcessDidExit(_ exitCode: Int32?)
}
