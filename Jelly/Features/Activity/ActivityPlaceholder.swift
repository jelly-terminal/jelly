import SwiftUI

struct ActivityPlaceholder: View {
    let symbol: String?
    let message: String
    let foreground: Color

    var body: some View {
        VStack(spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(foreground.opacity(0.3))
            } else {
                ProgressView().controlSize(.small)
            }
            Text(message)
                .font(.system(size: Metrics.chromeFontSize))
                .foregroundStyle(foreground.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
