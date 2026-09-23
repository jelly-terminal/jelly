import SwiftUI

struct TrialBanner: View {
    let daysRemaining: Int
    let onActivate: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.tint)
            Text(daysRemaining == 1 ? "1 day left in your trial" : "\(daysRemaining) days left in your trial")
                .fontWeight(.semibold)
            Spacer(minLength: 8)
            Button("Enter License Key", action: onActivate)
                .buttonStyle(.glass)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
        .font(.system(size: Metrics.chromeFontSize))
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: Metrics.bannerCornerRadius))
        .padding(.horizontal, Metrics.chromePadding * 2)
        .padding(.top, Metrics.chromePadding)
    }
}
