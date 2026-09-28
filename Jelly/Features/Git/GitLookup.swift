import Foundation

nonisolated enum GitLookup: Equatable, Sendable {
    case repository(URL)
    case notRepository
    case gitMissing
}
