public struct FuzzyMatch: Equatable, Sendable {
    public let score: Int
    public let positions: [Int]

    public init(score: Int, positions: [Int]) {
        self.score = score
        self.positions = positions
    }
}
