import AppKit
import JellyCore
import SwiftUI

struct ChangesList: View {
    let model: WindowModel
    let changes: ChangesModel
    let theme: Theme
    let isFocused: Bool
    let onSelect: (GitChange) -> Void

    var body: some View {
        let rows = changes.rows
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(rows) { row in
                        switch row {
                        case .section(let area, let count):
                            sectionHeader(area, count: count)
                        case .change(let change):
                            ChangeRowView(
                                change: change,
                                isSelected: change.id == changes.selection,
                                isFocused: isFocused,
                                theme: theme,
                                onSelect: { onSelect(change) }
                            )
                            .id(change.id)
                            .contextMenu { menu(for: change) }
                        }
                    }
                }
                .padding(Metrics.explorerPadding)
            }
            .onChange(of: changes.selection) { _, selection in
                guard let selection else { return }
                proxy.scrollTo(selection)
            }
        }
        .overlay {
            if let message = emptyMessage(hasRows: !rows.isEmpty) {
                Text(message)
                    .font(.system(size: Metrics.chromeFontSize))
                    .foregroundStyle(Color(theme.foreground).opacity(0.4))
            }
        }
        .task(id: changes.repository) {
            while !Task.isCancelled {
                await changes.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func sectionHeader(_ area: GitChange.Area, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(area.title.uppercased())
                .font(.system(size: Metrics.statusFontSize - 1, weight: .semibold))
                .tracking(0.4)
            Text("\(count)")
                .font(.system(size: Metrics.statusFontSize - 1, weight: .medium).monospacedDigit())
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(theme.foreground).opacity(0.45))
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .frame(height: Metrics.changesSectionHeight, alignment: .bottom)
    }

    @ViewBuilder
    private func menu(for change: GitChange) -> some View {
        if let repository = changes.repository {
            let url = repository.appending(path: change.path)
            if change.kind != .deleted {
                Button("Open File") { model.preview(url) }
                Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.path(percentEncoded: false), forType: .string)
            }
        }
    }

    private func emptyMessage(hasRows: Bool) -> String? {
        switch changes.state {
        case .idle, .loading: nil
        case .notRepository: "Not a git repository"
        case .gitMissing: "Git isn’t installed"
        case .ready: hasRows ? nil : changes.filter.isEmpty ? "No changes" : "No matches"
        }
    }
}
