import JellyCore
import SwiftUI

struct MarkdownView: View {
    let document: MarkdownDocument
    let style: MarkdownStyle
    @Binding var anchor: String?

    private var groups: [MarkdownBlockGroup] {
        MarkdownBlockGroup.grouping(document.blocks)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.markdownBlockSpacing) {
                    ForEach(groups, id: \.firstIndex) { group in
                        if group.paragraphs.isEmpty {
                            MarkdownBlockView(block: document.blocks[group.firstIndex], style: style, depth: 0)
                                .id(group.firstIndex)
                        } else {
                            MarkdownParagraphRun(paragraphs: group.paragraphs, style: style)
                                .id(group.firstIndex)
                        }
                    }
                }
                .textSelection(.enabled)
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
