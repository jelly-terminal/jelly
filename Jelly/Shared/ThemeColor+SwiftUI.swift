import JellyCore
import SwiftUI

extension Color {
    init(_ rgb: ThemeColor, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double(rgb.red) / 255,
            green: Double(rgb.green) / 255,
            blue: Double(rgb.blue) / 255,
            opacity: Double(rgb.alpha) / 255 * opacity
        )
    }
}
