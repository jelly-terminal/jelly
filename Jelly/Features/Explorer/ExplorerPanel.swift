import JellyCore
import SwiftUI

struct ExplorerPanel: View {
    let model: WindowModel
    @Bindable var explorer: ExplorerModel
    let theme: Theme
    let backgroundOpacity: Double

    @FocusState private var isFocused: Bool

    var body: some View {
        let foreground = Color(theme.foreground)
        VStack(spacing: 0) {
            header
            Rectangle().fill(foreground.opacity(0.08)).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(explorer.rows) { row in
                            ExplorerRowView(row: row, isSelected: row.entry.url == explorer.selection, isFocused: isFocused, theme: theme) {
                                explorer.selection = row.entry.url
                                isFocused = true
                                explorer.toggle(row.entry)
                            }
                                .id(row.id)
                                .onTapGesture(count: 2) { open(row.entry) }
                                .simultaneousGesture(TapGesture().onEnded {
                                    explorer.selection = row.entry.url
                                    isFocused = true
                                })
                                .onDrag { NSItemProvider(object: row.entry.url as NSURL) }
                        }
                    }
                    .padding(Metrics.explorerPadding)
                }
                .onChange(of: explorer.selection) { _, selection in
                    guard let selection else { return }
                    proxy.scrollTo(selection)
                }
            }
            .overlay {
                if explorer.rows.isEmpty {
                    Text(explorer.filter.isEmpty ? "Empty folder" : "No matches")
                        .font(.system(size: Metrics.chromeFontSize))
                        .foregroundStyle(foreground.opacity(0.4))
                }
            }
        }
        .frame(width: Metrics.explorerWidth)
        .frame(maxHeight: .infinity)
        .background {
            let shape = RoundedRectangle(cornerRadius: Metrics.paneCornerRadius, style: .continuous)
            shape
                .fill(Color(theme.background, opacity: backgroundOpacity))
                .overlay(shape.strokeBorder(foreground.opacity(0.1), lineWidth: 1))
        }
        .clipShape(.rect(cornerRadius: Metrics.paneCornerRadius, style: .continuous))
        .focusable()
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(phases: .down, action: handle)
        .onChange(of: model.explorerFocusRequest, initial: true) { isFocused = true }
        .task(id: model.workspace.selectedTab?.focusedPaneID) {
            while !Task.isCancelled {
                model.syncExplorer()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .onAppear { explorer.resume() }
        .onDisappear { explorer.stop() }
    }

    private var header: some View {
        let foreground = Color(theme.foreground)
        return HStack(spacing: 4) {
            headerButton("chevron.up", help: "Enclosing Folder (⌘↑)", action: explorer.goUp)
            Text(explorer.root?.lastPathComponent ?? "")
                .font(.system(size: Metrics.chromeFontSize, weight: .semibold))
                .foregroundStyle(foreground.opacity(0.75))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(explorer.root?.path(percentEncoded: false) ?? "")
            Spacer(minLength: 4)
            if !explorer.filter.isEmpty {
                Text(explorer.filter)
                    .font(.system(size: Metrics.statusFontSize, weight: .medium))
                    .foregroundStyle(Color(theme.accent))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(theme.accent).opacity(0.15), in: .capsule)
            }
            headerButton(explorer.showHidden ? "eye" : "eye.slash", help: explorer.showHidden ? "Hide Hidden Files" : "Show Hidden Files") {
                explorer.showHidden.toggle()
            }
            headerButton("xmark", help: "Close Explorer", action: model.toggleExplorer)
        }
        .padding(.horizontal, Metrics.paneHeaderPadding - 4)
        .frame(height: Metrics.paneHeaderHeight + 4)
    }

    private func headerButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Metrics.paneHeaderIconSize, weight: .semibold))
                .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.foreground).opacity(0.6))
        .help(help)
    }

    private func open(_ entry: ExplorerEntry) {
        if entry.isDirectory {
            explorer.setRoot(entry.url)
        } else {
            explorer.selection = entry.url
            model.preview(entry.url)
        }
    }

    private func activate(_ entry: ExplorerEntry) {
        explorer.selection = entry.url
        if entry.isDirectory {
            explorer.toggle(entry)
        } else {
            model.preview(entry.url)
        }
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        let command = press.modifiers.contains(.command)
        switch press.key {
        case .upArrow where command:
            explorer.goUp()
        case .downArrow where command:
            guard let entry = explorer.selectedEntry else { return .ignored }
            if entry.isDirectory { explorer.setRoot(entry.url) } else { model.preview(entry.url) }
        case .upArrow:
            explorer.moveSelection(by: -1)
        case .downArrow:
            explorer.moveSelection(by: 1)
        case .leftArrow:
            explorer.collapseSelection()
        case .rightArrow:
            explorer.expandSelection()
        case .return, .space:
            guard let entry = explorer.selectedEntry else { return .ignored }
            activate(entry)
        case .escape:
            if explorer.filter.isEmpty { model.focusTerminal() } else { explorer.filter = "" }
        case .delete, .deleteForward, KeyEquivalent("\u{08}"):
            guard !explorer.filter.isEmpty else { return .ignored }
            explorer.filter.removeLast()
        default:
            guard press.modifiers.isSubset(of: [.shift]), press.characters.count == 1,
                  let char = press.characters.first, char.isLetter || char.isNumber || char.isPunctuation
            else { return .ignored }
            explorer.filter.append(char)
            explorer.selection = explorer.rows.first?.entry.url
        }
        return .handled
    }
}
