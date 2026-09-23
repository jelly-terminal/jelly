import Foundation
import Security

public struct LicenseStore: Sendable {
    public let service: String

    public init(service: String) {
        self.service = service
    }

    public static func standard(bundleID: String = Bundle.main.bundleIdentifier ?? "com.monawwar.Jelly") -> LicenseStore {
        LicenseStore(service: "\(bundleID).license")
    }

    public func load() -> License? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(License.self, from: data)
    }

    public func save(_ license: License) {
        guard let data = try? JSONEncoder().encode(license) else { return }
        SecItemDelete(baseQuery as CFDictionary)
        var add = baseQuery
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    public func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "license",
        ]
    }
}
