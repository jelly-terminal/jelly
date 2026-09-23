import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Jelly"
    }

    static let gumroadProductPermalink = "jelly"
    static let gumroadProductURL = URL(string: "https://monawwar.gumroad.com/l/jelly")!
}
