import AppKit
import SwiftUI

extension EnvironmentValues {
    @Entry var textKeyHandler: ((NSEvent) -> Bool)? = nil
}
