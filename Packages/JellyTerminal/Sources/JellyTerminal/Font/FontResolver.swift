import AppKit
import JellyCore

public enum FontResolver {
    public static let systemMonospacedName = "SF Mono"

    public struct Result {
        public var font: NSFont
        public var diagnostics: [Diagnostic]
    }

    public static func normalize(_ name: String) -> String {
        name.lowercased().filter { !$0.isWhitespace && $0 != "-" && $0 != "_" }
    }

    public static func matchFamily(_ requested: String, in families: [String]) -> String? {
        let key = normalize(requested)
        return families.first { $0 == requested } ?? families.first { normalize($0) == key }
    }

    public static func nerdFontFallback(for primary: String, in families: [String]) -> String? {
        guard !primary.localizedCaseInsensitiveContains("nerd") else { return nil }
        let preferred = ["Symbols Nerd Font Mono", "Symbols Nerd Font"]
        if let symbols = preferred.first(where: families.contains) { return symbols }
        return families.first { $0.hasSuffix("Nerd Font Mono") } ?? families.first { $0.hasSuffix("Nerd Font") }
    }

    public static func installedFamilies() -> [String] {
        NSFontManager.shared.availableFontFamilies
    }

    public static func monospacedFamilies() -> [String] {
        let manager = NSFontManager.shared
        return manager.availableFontFamilies.filter { family in
            guard let font = manager.font(withFamily: family, traits: [], weight: 5, size: 12) else { return false }
            return font.isFixedPitch || font.fontDescriptor.symbolicTraits.contains(.monoSpace)
        }
    }

    public static func resolve(_ settings: FontSettings, size: Double? = nil) -> Result {
        let pointSize = CGFloat(size ?? settings.size)
        var diagnostics: [Diagnostic] = []

        var base: NSFont
        if normalize(settings.family) == normalize(systemMonospacedName) {
            base = .monospacedSystemFont(ofSize: pointSize, weight: .regular)
        } else if let family = matchFamily(settings.family, in: installedFamilies()),
                  let font = NSFontManager.shared.font(withFamily: family, traits: [], weight: 5, size: pointSize) {
            base = font
        } else {
            diagnostics.append(Diagnostic(message: "settings.font.family: '\(settings.family)' is not installed, using \(systemMonospacedName)"))
            base = .monospacedSystemFont(ofSize: pointSize, weight: .regular)
        }

        let (features, invalid) = FontFeature.resolve(specs: settings.features, ligatures: settings.ligatures)
        diagnostics += invalid.map { Diagnostic(message: "settings.font.features: '\($0)' is not an OpenType feature tag") }

        var cascade: [NSFontDescriptor] = []
        let families = installedFamilies()
        var fallback = settings.fallback
        if fallback.isEmpty, let nerd = nerdFontFallback(for: base.familyName ?? settings.family, in: families) {
            fallback = [nerd]
        }
        for name in fallback {
            guard let family = matchFamily(name, in: families) else {
                diagnostics.append(Diagnostic(message: "settings.font.fallback: '\(name)' is not installed"))
                continue
            }
            cascade.append(NSFontDescriptor(fontAttributes: [.family: family]))
        }

        var attributes: [NSFontDescriptor.AttributeName: Any] = [:]
        if !features.isEmpty {
            attributes[NSFontDescriptor.AttributeName(kCTFontFeatureSettingsAttribute as String)] = features.map(\.attribute)
        }
        if !cascade.isEmpty {
            attributes[.cascadeList] = cascade
        }
        if !attributes.isEmpty {
            let descriptor = base.fontDescriptor.addingAttributes(attributes)
            base = NSFont(descriptor: descriptor, size: pointSize) ?? base
        }
        return Result(font: base, diagnostics: diagnostics)
    }
}
