import Foundation
import JellyCore

struct GumroadLicenseVerifier {
    enum VerifyError: Error {
        case network
        case rejected(String)
        case refunded
    }

    private struct Purchase: Decodable {
        let email: String?
        let refunded: Bool?
        let disputed: Bool?
        let chargebacked: Bool?
    }

    private struct Response: Decodable {
        let success: Bool
        let message: String?
        let purchase: Purchase?
    }

    let productPermalink: String

    func verify(key: String) async throws -> License {
        var request = URLRequest(url: URL(string: "https://api.gumroad.com/v2/licenses/verify")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "product_permalink", value: productPermalink),
            URLQueryItem(name: "license_key", value: key),
            URLQueryItem(name: "increment_uses_count", value: "false"),
        ]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse
        else { throw VerifyError.network }

        let decoded = try? JSONDecoder().decode(Response.self, from: data)
        guard http.statusCode == 200, let decoded, decoded.success else {
            throw VerifyError.rejected(decoded?.message ?? "This license key isn't valid.")
        }

        let purchase = decoded.purchase
        if purchase?.refunded == true || purchase?.disputed == true || purchase?.chargebacked == true {
            throw VerifyError.refunded
        }
        return License(key: key, email: purchase?.email, verifiedAt: Date())
    }
}
