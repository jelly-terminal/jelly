import JellyCore
import SwiftUI

struct MarkdownView: View {
    let document: MarkdownDocument
    let style: MarkdownStyle
    @Binding var anchor: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Metrics.markdownBlockSpacing) {
                    ForEach(Array(document.blocks.enumerated()), id: \.offset) { index, block in
                        MarkdownBlockView(block: block, style: style, depth: 0)
                            .id(index)
                    }
                }
                .frame(maxWidth: Metrics.markdownMaxWidth, alignment: .leading)
                .padding(Metrics.viewerPadding)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: anchor, initial: true) { _, target in
                guard let target else { return }
                let normalized = target.lowercased()
                if let heading = document.outline.first(where: { $0.anchor == normalized }) {
                    withAnimation(.smooth) { proxy.scrollTo(heading.blockIndex, anchor: .top) }
                }
                anchor = nil
            }
        }
    }
}
