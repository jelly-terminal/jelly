import CoreText
import Foundation

public struct FontFeature: Equatable, Sendable {
    public var tag: String
    public var value: Int

    public init?(_ spec: String) {
        var text = spec.trimmingCharacters(in: .whitespaces)
        var value = 1
        if text.hasPrefix("-") {
            value = 0
            text.removeFirst()
        } else if text.hasPrefix("+") {
            text.removeFirst()
        }
        if let equals = text.firstIndex(of: "=") {
            guard let explicit = Int(text[text.index(after: equals)...]), explicit >= 0 else { return nil }
            value = explicit
            text = String(text[..<equals])
        }
        guard text.count == 4, text.unicodeScalars.allSatisfy({ $0.isASCII && $0.properties.isAlphabetic || ("0"..."9").contains($0) }) else {
            return nil
        }
        self.tag = text
        self.value = value
    }

    init(tag: String, value: Int) {
        self.tag = tag
        self.value = value
    }

    public static func resolve(specs: [String], ligatures: Bool) -> (features: [FontFeature], invalid: [String]) {
        var features: [FontFeature] = []
        var invalid: [String] = []
        if !ligatures {
            features = ["calt", "liga", "dlig"].map { FontFeature(tag: $0, value: 0) }
        }
        for spec in specs {
            guard let feature = FontFeature(spec) else {
                invalid.append(spec)
                continue
            }
            features.removeAll { $0.tag == feature.tag }
            features.append(feature)
        }
        return (features, invalid)
    }

    var attribute: [CFString: Any] {
        [kCTFontOpenTypeFeatureTag: tag, kCTFontOpenTypeFeatureValue: value]
    }
}
