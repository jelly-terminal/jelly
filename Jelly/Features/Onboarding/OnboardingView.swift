import AppKit
import JellyCore
import SwiftUI

struct OnboardingView: View {
    let theme: Theme
    let keybinds: Keybinds
    let onDone: () -> Void

    private var text: Color { Color(theme.foreground) }
    private var secondary: Color { Color(theme.foreground).opacity(0.6) }
    private var faint: Color { Color(theme.foreground).opacity(0.08) }

    var body: some View {
        VStack(spacing: Metrics.onboardingSpacing) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: Metrics.onboardingIconSize, height: Metrics.onboardingIconSize)
            VStack(spacing: 4) {
                Text("Welcome to \(AppInfo.name)")
                    .font(.system(size: Metrics.onboardingTitleSize, weight: .bold))
                    .foregroundStyle(text)
                Text("A native terminal built around sessions.")
                    .foregroundStyle(secondary)
            }
            VStack(spacing: Metrics.onboardingRowSpacing) {
                ForEach(OnboardingFeature.all) { feature in
                    row(feature)
                }
            }
            Button(action: onDone) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
        }
        .padding(Metrics.onboardingPadding)
        .frame(width: Metrics.onboardingWidth)
        .background(Color(theme.background))
    }

    private func row(_ feature: OnboardingFeature) -> some View {
        HStack(spacing: Metrics.onboardingRowSpacing) {
            Image(systemName: feature.symbol)
                .font(.system(size: Metrics.onboardingSymbolSize))
                .foregroundStyle(Color(theme.accent))
                .frame(width: Metrics.onboardingSymbolWidth)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(text)
                Text(feature.detail)
                    .foregroundStyle(secondary)
            }
            Spacer(minLength: 0)
            if let chord = keybinds.chord(for: feature.action) {
                Text(chord.symbols)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(secondary)
                    .padding(.horizontal, Metrics.onboardingKeyPaddingH)
                    .padding(.vertical, Metrics.onboardingKeyPaddingV)
                    .background(faint, in: .rect(cornerRadius: Metrics.paneButtonCornerRadius))
            }
        }
    }
}
