import JellyCore
import SwiftUI

struct MarkdownListView: View {
    let list: MarkdownList
    let style: MarkdownStyle
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    marker(for: item, at: index)
                        .frame(minWidth: Metrics.markdownListMarkerWidth, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(item.blocks.enumerated()), id: \.offset) { _, block in
                            MarkdownBlockView(block: block, style: style, depth: depth + 1)
                        }
                    }
                    .opacity(item.checked == true ? 0.6 : 1)
                }
            }
        }
    }

    @ViewBuilder
    private func marker(for item: MarkdownList.Item, at index: Int) -> some View {
        if let checked = item.checked {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .font(.system(size: Metrics.markdownBodySize - 1))
                .foregroundStyle(checked ? style.accent : style.secondary)
        } else if let start = list.start {
            Text("\(start + index).")
                .font(style.bodyFont.monospacedDigit())
                .foregroundStyle(style.secondary)
        } else {
            Text(depth == 0 ? "•" : depth == 1 ? "◦" : "▪︎")
                .font(style.bodyFont)
                .foregroundStyle(style.secondary)
        }
    }
}
