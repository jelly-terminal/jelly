import JellyCore
import SwiftUI

struct WhatsNewView: View {
    let version: String
    let document: MarkdownDocument
    let style: MarkdownStyle
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("What’s New in \(AppInfo.name)")
                    .font(.system(size: Metrics.whatsNewTitleSize, weight: .bold))
                    .foregroundStyle(style.text)
                Text("Version \(version)")
                    .foregroundStyle(style.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Metrics.viewerPadding)
            .padding(.vertical, Metrics.whatsNewHeaderPadding)
            Rectangle().fill(style.faint).frame(height: 1)
            MarkdownView(document: document, style: style, anchor: .constant(nil))
            Rectangle().fill(style.faint).frame(height: 1)
            HStack {
                Spacer()
                Button("Continue", action: onDone)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(Metrics.whatsNewHeaderPadding)
        }
        .frame(width: Metrics.whatsNewWidth, height: Metrics.whatsNewHeight)
        .background(Color(style.theme.background))
    }
}
