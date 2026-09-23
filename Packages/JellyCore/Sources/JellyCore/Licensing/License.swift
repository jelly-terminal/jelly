import Foundation

public struct License: Sendable, Codable, Equatable {
    public var key: String
    public var email: String?
    public var verifiedAt: Date

    public init(key: String, email: String?, verifiedAt: Date) {
        self.key = key
        self.email = email
        self.verifiedAt = verifiedAt
    }
}
