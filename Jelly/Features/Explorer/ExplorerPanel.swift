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
            switch model.explorerMode {
            case .files: files
            case .changes:
                ChangesList(model: model, changes: model.changes, theme: theme, isFocused: isFocused) { change in
                    model.changes.selection = change.id
                    isFocused = true
                    model.showDiff(change)
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
        .onKeyPress(phases: .down) { model.explorerMode == .files ? handle($0) : handleChanges($0) }
        .onChange(of: model.explorerFocusRequest, initial: true) { isFocused = true }
        .task(id: model.workspace.selectedTab?.focusedPaneID) {
            while !Task.isCancelled {
                model.syncExplorer()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .task(id: model.changes.repository) {
            while !Task.isCancelled {
                await model.changes.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
        .onAppear { explorer.resume() }
        .onDisappear { explorer.stop() }
    }

    private var files: some View {
        let foreground = Color(theme.foreground)
        let decorations = model.changes.decorations
        return ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(explorer.rows) { row in
                            ExplorerRowView(
                                row: row,
                                isSelected: row.entry.url == explorer.selection,
                                isFocused: isFocused,
                                status: decorations.kind(for: row.entry),
                                theme: theme,
                                onToggle: {
                                    select(row.entry)
                                    explorer.toggle(row.entry)
                                },
                                onSelect: { select(row.entry) },
                                onOpen: { open(row.entry) }
                            )
                                .id(row.id)
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

    private var header: some View {
        HStack(spacing: 4) {
            modeButton(.files, symbol: "folder", help: "Files")
            modeButton(.changes, symbol: "arrow.triangle.branch", help: "Changes")
            Rectangle()
                .fill(Color(theme.foreground).opacity(0.12))
                .frame(width: 1, height: Metrics.paneHeaderIconSize + 4)
                .padding(.horizontal, 2)
            switch model.explorerMode {
            case .files: filesHeader
            case .changes: changesHeader
            }
            headerButton("xmark", help: "Close Explorer", action: model.hideExplorer)
        }
        .padding(.horizontal, Metrics.paneHeaderPadding - 4)
        .frame(height: Metrics.paneHeaderHeight + 4)
    }

    @ViewBuilder
    private var filesHeader: some View {
        headerButton("chevron.up", help: "Enclosing Folder (⌘↑)", action: explorer.goUp)
        title(explorer.root?.lastPathComponent ?? "", help: explorer.root?.path(percentEncoded: false) ?? "")
        Spacer(minLength: 4)
        filterBadge(explorer.filter)
        headerButton(explorer.showHidden ? "eye" : "eye.slash", help: explorer.showHidden ? "Hide Hidden Files" : "Show Hidden Files") {
            explorer.showHidden.toggle()
        }
    }

    @ViewBuilder
    private var changesHeader: some View {
        let changes = model.changes
        let status = changes.status
        title(status.map { $0.branch ?? $0.commit.map { String($0.prefix(7)) } ?? "detached" } ?? "",
              help: changes.repository?.path(percentEncoded: false) ?? "")
        if let status, status.ahead + status.behind > 0 {
            Text([status.ahead > 0 ? "↑\(status.ahead)" : nil, status.behind > 0 ? "↓\(status.behind)" : nil].compactMap { $0 }.joined(separator: " "))
                .font(.system(size: Metrics.statusFontSize, weight: .medium).monospacedDigit())
                .foregroundStyle(Color(theme.foreground).opacity(0.5))
                .help(status.upstream.map { "Compared with \($0)" } ?? "")
        }
        Spacer(minLength: 4)
        filterBadge(changes.filter)
    }

    private func title(_ text: String, help: String) -> some View {
        Text(text)
            .font(.system(size: Metrics.chromeFontSize, weight: .semibold))
            .foregroundStyle(Color(theme.foreground).opacity(0.75))
            .lineLimit(1)
            .truncationMode(.middle)
            .help(help)
    }

    @ViewBuilder
    private func filterBadge(_ filter: String) -> some View {
        if !filter.isEmpty {
            Text(filter)
                .font(.system(size: Metrics.statusFontSize, weight: .medium))
                .foregroundStyle(Color(theme.accent))
                .lineLimit(1)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(theme.accent).opacity(0.15), in: .capsule)
        }
    }

    private func modeButton(_ mode: ExplorerMode, symbol: String, help: String) -> some View {
        let isSelected = model.explorerMode == mode
        return Button {
            model.explorerMode = mode
            model.syncExplorer()
            isFocused = true
        } label: {
            Image(systemName: symbol)
                .font(.system(size: Metrics.paneHeaderIconSize, weight: .semibold))
                .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                .background {
                    RoundedRectangle(cornerRadius: Metrics.paneButtonCornerRadius, style: .continuous)
                        .fill(isSelected ? Color(theme.accent).opacity(0.18) : .clear)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color(theme.accent) : Color(theme.foreground).opacity(0.5))
        .help(help)
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

    private func select(_ entry: ExplorerEntry) {
        explorer.selection = entry.url
        isFocused = true
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

    private func removeLastFilterCharacter() -> KeyPress.Result {
        guard !explorer.filter.isEmpty else { return .ignored }
        explorer.filter.removeLast()
        explorer.selection = explorer.rows.first?.entry.url
        return .handled
    }

    private func handleChanges(_ press: KeyPress) -> KeyPress.Result {
        let changes = model.changes
        switch press.key {
        case .upArrow, .downArrow:
            changes.moveSelection(by: press.key == .upArrow ? -1 : 1)
            if model.viewer?.diff != nil, let change = changes.selectedChange { model.showDiff(change) }
        case .return, .space:
            guard let change = changes.selectedChange else { return .ignored }
            model.showDiff(change)
        case .escape:
            if changes.filter.isEmpty { model.focusTerminal() } else { changes.filter = "" }
        case .delete, .deleteForward, KeyEquivalent("\u{08}"):
            return removeLastChangesFilterCharacter()
        default:
            if press.characters == "\u{7F}" || press.characters == "\u{08}" {
                return removeLastChangesFilterCharacter()
            }
            guard let char = typedCharacter(press) else { return .ignored }
            changes.filter.append(char)
            changes.selection = changes.changes.first?.id
        }
        return .handled
    }

    private func removeLastChangesFilterCharacter() -> KeyPress.Result {
        let changes = model.changes
        guard !changes.filter.isEmpty else { return .ignored }
        changes.filter.removeLast()
        changes.selection = changes.changes.first?.id
        return .handled
    }

    private func typedCharacter(_ press: KeyPress) -> Character? {
        guard press.modifiers.isSubset(of: [.shift]), press.characters.count == 1,
              let char = press.characters.first, char.isLetter || char.isNumber || char.isPunctuation
        else { return nil }
        return char
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
            return removeLastFilterCharacter()
        default:
            if press.characters == "\u{7F}" || press.characters == "\u{08}" {
                return removeLastFilterCharacter()
            }
            guard let char = typedCharacter(press) else { return .ignored }
            explorer.filter.append(char)
            explorer.selection = explorer.rows.first?.entry.url
        }
        return .handled
    }
}
