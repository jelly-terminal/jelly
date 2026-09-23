import Testing
@testable import JellyTerminal

struct FontTests {
    @Test func familyMatchingIgnoresCaseSpacesAndHyphens() {
        let installed = ["FiraCode Nerd Font", "JetBrains Mono", "Iosevka Term"]
        #expect(FontResolver.matchFamily("Fira Code Nerd Font", in: installed) == "FiraCode Nerd Font")
        #expect(FontResolver.matchFamily("jetbrains-mono", in: installed) == "JetBrains Mono")
        #expect(FontResolver.matchFamily("Iosevka", in: installed) == nil)
    }

    @Test func nerdFontFallbackPrefersSymbolsThenMonoAndSkipsNerdPrimaries() {
        #expect(FontResolver.nerdFontFallback(for: "SF Mono", in: ["0xProto Nerd Font", "0xProto Nerd Font Mono"]) == "0xProto Nerd Font Mono")
        #expect(FontResolver.nerdFontFallback(for: "SF Mono", in: ["Hack Nerd Font Mono", "Symbols Nerd Font Mono"]) == "Symbols Nerd Font Mono")
        #expect(FontResolver.nerdFontFallback(for: "FiraCode Nerd Font", in: ["Symbols Nerd Font Mono"]) == nil)
        #expect(FontResolver.nerdFontFallback(for: "Menlo", in: ["Menlo"]) == nil)
    }

    @Test func featuresParseAndLigaturesOffCanBeOverridden() {
        #expect(FontFeature("ss02") == FontFeature(tag: "ss02", value: 1))
        #expect(FontFeature("-liga") == FontFeature(tag: "liga", value: 0))
        #expect(FontFeature("cv01=3") == FontFeature(tag: "cv01", value: 3))
        #expect(FontFeature("toolong") == nil)
        #expect(FontFeature("ss0!") == nil)

        let (features, invalid) = FontFeature.resolve(specs: ["calt", "zero", "bad!"], ligatures: false)
        #expect(features.map(\.tag) == ["liga", "dlig", "calt", "zero"])
        #expect(features.first { $0.tag == "calt" }?.value == 1)
        #expect(invalid == ["bad!"])
    }

    @Test func xtversionAnswersAsJellyAndOtherRepliesPassThrough() {
        let swiftTerm = ArraySlice(Array("\u{1B}P>|SwiftTerm(1.20.0)\u{1B}\\".utf8))
        #expect(Array(QueryResponder.rewrite(swiftTerm, version: "0.1.0")) == Array("\u{1B}P>|Jelly 0.1.0\u{1B}\\".utf8))

        let da1 = ArraySlice(Array("\u{1B}[?65;1;2;6;21;22;17;28c".utf8))
        #expect(QueryResponder.rewrite(da1, version: "0.1.0") == da1)
    }
}
