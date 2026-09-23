import JellyCore
import SwiftUI

struct MarkdownTableView: View {
    let table: MarkdownTable
    let style: MarkdownStyle

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                row(table.header, isHeader: true, index: 0)
                ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                    Rectangle().fill(style.faint).frame(height: 1).gridCellUnsizedAxes(.horizontal)
                    row(cells, isHeader: false, index: index + 1)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: Metrics.markdownCornerRadius).strokeBorder(style.faint))
            .clipShape(.rect(cornerRadius: Metrics.markdownCornerRadius))
        }
        .scrollIndicators(.never)
    }

    private func row(_ cells: [String], isHeader: Bool, index: Int) -> some View {
        GridRow {
            ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                Text(style.inline(cell))
                    .font(isHeader ? style.bodyFont.weight(.semibold) : style.bodyFont)
                    .foregroundStyle(style.text)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: alignment(column))
                    .gridColumnAlignment(horizontalAlignment(column))
            }
        }
        .background(isHeader ? style.fill : index.isMultiple(of: 2) ? style.fill.opacity(0.5) : .clear)
    }

    private func alignment(_ column: Int) -> Alignment {
        switch table.alignments[column] {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private func horizontalAlignment(_ column: Int) -> HorizontalAlignment {
        switch table.alignments[column] {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
