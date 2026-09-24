import Testing
@testable import JellyCore

struct FuzzyMatcherTests {
    private func score(_ query: String, _ candidate: String) -> Int? {
        FuzzyMatcher.match(query, in: candidate)?.score
    }

    @Test func matchesSubsequencesIgnoringCaseAndSpaces() {
        #expect(FuzzyMatcher.match("SPLR", in: "Split Right")?.positions == [0, 1, 2, 6])
        #expect(FuzzyMatcher.match("split r", in: "Split Right") != nil)
        #expect(FuzzyMatcher.match("rs", in: "Split Right") == nil)
        #expect(FuzzyMatcher.match("splitting", in: "Split") == nil)
    }

    @Test func prefersWordStartsAndRuns() {
        #expect(score("sr", "Split Right")! > score("sr", "Users Rust")!)
        #expect(score("tab", "New Tab")! > score("tab", "Toggle a Bar")!)
        #expect(score("zp", "Zoom Pane")! > score("zp", "Resize Panels")!)
    }

    @Test func treatsCamelCaseAsWordStarts() {
        #expect(FuzzyMatcher.match("jd", in: "jellyDark")?.positions == [0, 5])
    }
}
