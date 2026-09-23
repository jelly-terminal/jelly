public struct Theme: Equatable, Sendable, Identifiable {
    public enum Appearance: String, Sendable {
        case dark
        case light
    }

    public var id: String
    public var name: String
    public var appearance: Appearance
    public var background: RGBColor
    public var foreground: RGBColor
    public var palette: [RGBColor]
    public var cursor: RGBColor
    public var cursorText: RGBColor
    public var selection: RGBColor
    public var selectionText: RGBColor?
    public var accent: RGBColor

    public init(
        id: String,
        name: String,
        appearance: Appearance? = nil,
        background: RGBColor,
        foreground: RGBColor,
        palette: [RGBColor],
        cursor: RGBColor? = nil,
        cursorText: RGBColor? = nil,
        selection: RGBColor? = nil,
        selectionText: RGBColor? = nil,
        accent: RGBColor? = nil
    ) {
        precondition(palette.count == 16)
        self.id = id
        self.name = name
        self.appearance = appearance ?? (background.isDark ? .dark : .light)
        self.background = background
        self.foreground = foreground
        self.palette = palette
        self.cursor = cursor ?? foreground
        self.cursorText = cursorText ?? background
        self.selection = selection ?? palette[8]
        self.selectionText = selectionText
        self.accent = accent ?? palette[4]
    }
}
