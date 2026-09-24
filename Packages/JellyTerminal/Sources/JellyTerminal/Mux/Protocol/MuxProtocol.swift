import Foundation

public enum MuxProtocol {
    public static let version = 1
    static let supportedVersions: ClosedRange<Int> = 1...1
    static let helperArgument = "--mux"
    static let helperName = "jelly-mux"

    static func socketPath(bundleID: String) -> String {
        (NSTemporaryDirectory() as NSString).appendingPathComponent("\(bundleID).mux")
    }
}
