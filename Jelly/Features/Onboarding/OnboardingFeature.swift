import JellyCore

struct OnboardingFeature: Identifiable {
    let symbol: String
    let title: String
    let detail: String
    let action: KeyAction

    var id: String { title }

    static let all = [
        OnboardingFeature(
            symbol: "square.stack.3d.up",
            title: "Sessions",
            detail: "Named workspaces, each with its own tabs and panes.",
            action: .sessionNew
        ),
        OnboardingFeature(
            symbol: "rectangle.split.2x1",
            title: "Split panes",
            detail: "Run several shells side by side in one tab.",
            action: .splitRight
        ),
        OnboardingFeature(
            symbol: "folder",
            title: "Built-in explorer",
            detail: "Browse and preview files that follow your shell’s directory.",
            action: .explorerToggle
        ),
        OnboardingFeature(
            symbol: "command",
            title: "Command palette",
            detail: "Search actions, tabs, sessions and themes.",
            action: .paletteToggle
        ),
    ]
}
