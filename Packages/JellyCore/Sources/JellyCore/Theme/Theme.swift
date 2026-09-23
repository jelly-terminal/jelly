public struct Theme: Equatable, Sendable, Identifiable {
    public enum Appearance: String, Sendable {
        case dark
        case light
    }

    public var id: String
    public var name: String
    public var appearance: Appearance
    public var background: ThemeColor
    public var foreground: ThemeColor
    public var palette: [ThemeColor]
    public var cursor: ThemeColor
    public var cursorText: ThemeColor
    public var selection: ThemeColor
    public var selectionText: ThemeColor?
    public var accent: ThemeColor

    public init(
        id: String,
        name: String,
        appearance: Appearance? = nil,
        background: ThemeColor,
        foreground: ThemeColor,
        palette: [ThemeColor],
        cursor: ThemeColor? = nil,
        cursorText: ThemeColor? = nil,
        selection: ThemeColor? = nil,
        selectionText: ThemeColor? = nil,
        accent: ThemeColor? = nil
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
