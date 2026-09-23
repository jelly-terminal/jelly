import JellyCore
import SwiftUI

struct DiagnosticsBanner: View {
    let diagnostics: [Diagnostic]
    let onOpenConfig: () -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(diagnostics.count == 1 ? "1 config problem" : "\(diagnostics.count) config problems")
                    .fontWeight(.semibold)
                Text(diagnostics[0].description)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if diagnostics.count > 1 {
                    Button(isExpanded ? "Less" : "All") { isExpanded.toggle() }
                        .buttonStyle(.glass)
                }
                Button("Open Config", action: onOpenConfig)
                    .buttonStyle(.glass)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
            }
            if isExpanded {
                ForEach(Array(diagnostics.enumerated()), id: \.offset) { _, diagnostic in
                    Text(diagnostic.description)
                        .font(.system(size: Metrics.statusFontSize, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .font(.system(size: Metrics.chromeFontSize))
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: Metrics.bannerCornerRadius))
        .padding(.horizontal, Metrics.chromePadding * 2)
        .padding(.top, Metrics.chromePadding)
    }
}
