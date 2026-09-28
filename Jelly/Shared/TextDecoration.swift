import AppKit

enum TextDecoration: Equatable {
    case underline(NSRange, color: NSColor)
    case bar(NSRange, x: CGFloat, width: CGFloat, color: NSColor)
    case box(NSRange, x: CGFloat, padding: CGFloat, cornerRadius: CGFloat, color: NSColor)
    case rule(NSRange, color: NSColor)
}
