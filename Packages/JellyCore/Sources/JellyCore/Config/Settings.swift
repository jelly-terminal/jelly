import Foundation

public struct Settings: Equatable, Sendable {
    public var theme: ThemeSelection = .fixed("jelly-dark")
    public var scrollback = 10_000
    public var confirmQuit = true
    public var font = FontSettings()
    public var window = WindowSettings()
    public var cursor = CursorSettings()
    public var shell = ShellSettings()
    public var clipboard = ClipboardSettings()
    public var updates = UpdateSettings()

    public init() {}
}

public enum ThemeSelection: Equatable, Sendable {
    case fixed(String)
    case adaptive(light: String, dark: String)

    public func id(dark: Bool) -> String {
        switch self {
        case .fixed(let id): id
        case .adaptive(let light, let darkID): dark ? darkID : light
        }
    }
}

public enum CellAdjustment: Equatable, Sendable {
    case percent(Double)
    case points(Double)

    public init?(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix("%") {
            guard let value = Double(trimmed.dropLast()), value > 0 else { return nil }
            self = .percent(value)
        } else {
            guard let value = Double(trimmed) else { return nil }
            self = .points(value)
        }
    }

    public func apply(to base: Double) -> Double {
        switch self {
        case .percent(let percent): base * percent / 100
        case .points(let points): base + points
        }
    }
}

public struct FontSettings: Equatable, Sendable {
    public var family = "SF Mono"
    public var size = 13.0
    public var fallback: [String] = []
    public var ligatures = true
    public var features: [String] = []
    public var thicken = false
    public var cellWidth = CellAdjustment.percent(100)
    public var cellHeight = CellAdjustment.percent(100)
}

public struct WindowSettings: Equatable, Sendable {
    public var backgroundOpacity = 1.0
    public var blur = 0
    public var paddingX = 10.0
    public var paddingY = 8.0
    public var sidebar = true
    public var statusBar = true
}

public struct CursorSettings: Equatable, Sendable {
    public enum Style: String, Sendable {
        case block
        case bar
        case underline
    }

    public var style = Style.block
    public var blink = true
}

public struct ShellSettings: Equatable, Sendable {
    public enum WorkingDirectory: Equatable, Sendable {
        case inherit
        case home
        case path(String)
    }

    public var program: String?
    public var args: [String] = []
    public var workingDirectory = WorkingDirectory.inherit
    public var env: [String: String] = [:]
}

public struct ClipboardSettings: Equatable, Sendable {
    public var copyOnSelect = false
    public var osc52Read = false
}

public struct UpdateSettings: Equatable, Sendable {
    public var check = true
    public var autoInstall = false
}
