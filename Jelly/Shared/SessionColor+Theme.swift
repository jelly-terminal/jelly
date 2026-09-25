import JellyCore
import SwiftUI

extension SessionColor {
    func color(_ theme: Theme) -> Color {
        Color(theme.palette[paletteIndex])
    }
}
