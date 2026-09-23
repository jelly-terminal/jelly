import AppKit

public enum FontCatalog {
    public static func monospacedFamilies() -> [String] {
        let manager = NSFontManager.shared
        let families = manager.availableFontFamilies.filter { family in
            guard !family.hasPrefix("."),
                  let members = manager.availableMembers(ofFontFamily: family),
                  let name = members.first?.first as? String,
                  let font = NSFont(name: name, size: 12)
            else { return false }
            return font.isFixedPitch
        }
        return ["SF Mono"] + families.filter { $0 != "SF Mono" }
    }
}
