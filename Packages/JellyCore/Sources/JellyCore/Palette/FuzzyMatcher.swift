public enum FuzzyMatcher {
    private static let boundaryBonus = 8
    private static let consecutiveBonus = 8
    private static let maxLeadingPenalty = 5

    public static func match(_ query: String, in candidate: String) -> FuzzyMatch? {
        let needle = query.lowercased().filter { !$0.isWhitespace }.map { $0 }
        guard !needle.isEmpty else { return FuzzyMatch(score: 0, positions: []) }
        let original = Array(candidate)
        let haystack = original.map { Character($0.lowercased()) }
        guard needle.count <= haystack.count else { return nil }

        let bonuses = haystack.indices.map { bonus(at: $0, in: original) }
        var scores = [[Int?]](repeating: [Int?](repeating: nil, count: haystack.count), count: needle.count)
        var previous = [[Int]](repeating: [Int](repeating: -1, count: haystack.count), count: needle.count)

        for i in haystack.indices where haystack[i] == needle[0] {
            scores[0][i] = 1 + bonuses[i] - min(i, maxLeadingPenalty)
        }
        for j in needle.indices.dropFirst() {
            for i in haystack.indices where i >= j && haystack[i] == needle[j] {
                var best: Int?
                for k in (j - 1)..<i {
                    guard let prior = scores[j - 1][k] else { continue }
                    let link = k == i - 1 ? consecutiveBonus : -(i - k - 1)
                    let total = prior + link
                    if best == nil || total > best! {
                        best = total
                        previous[j][i] = k
                    }
                }
                if let best { scores[j][i] = best + 1 + bonuses[i] }
            }
        }

        let last = needle.count - 1
        guard let end = haystack.indices.filter({ scores[last][$0] != nil }).max(by: { scores[last][$0]! < scores[last][$1]! })
        else { return nil }

        var positions = [end]
        var j = last
        while j > 0 {
            positions.append(previous[j][positions.last!])
            j -= 1
        }
        return FuzzyMatch(score: scores[last][end]!, positions: positions.reversed())
    }

    private static func bonus(at index: Int, in characters: [Character]) -> Int {
        guard index > 0 else { return boundaryBonus }
        let before = characters[index - 1]
        let current = characters[index]
        if !before.isLetter && !before.isNumber { return boundaryBonus }
        if before.isLowercase && current.isUppercase { return boundaryBonus }
        return 0
    }
}
