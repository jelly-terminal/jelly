import JellyCore
import SwiftUI

struct ImportSheet: View {
    @State var pending: PendingImport
    let onImport: (PendingImport) -> Void
    let onInsertPath: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import \(pending.url.lastPathComponent)")
                        .font(.headline)
                    Text(pending.plan.summary)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !pending.plan.themes.isEmpty {
                        section("Themes") {
                            ForEach(pending.plan.themes, id: \.theme.id) { item in
                                ThemeRow(theme: item.theme, replaces: item.replaces)
                            }
                        }
                    }
                    if !pending.plan.settingChanges.isEmpty {
                        section("Settings") { changes(pending.plan.settingChanges) }
                    }
                    if !pending.plan.keybindChanges.isEmpty {
                        section("Keybinds") { changes(pending.plan.keybindChanges) }
                    }
                    if !pending.plan.diagnostics.isEmpty {
                        section("Warnings") {
                            ForEach(Array(pending.plan.diagnostics.enumerated()), id: \.offset) { _, diagnostic in
                                Label(diagnostic.description, systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 280)

            if let first = pending.plan.themes.first {
                Toggle("Switch to \(first.theme.name)", isOn: $pending.switchToTheme)
            }

            HStack {
                Button("Insert Path Instead", action: onInsertPath)
                Spacer()
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("Import") { onImport(pending) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.glassProminent)
                    .disabled(!pending.plan.canApply || (pending.plan.isEmpty && pending.themeToActivate == nil))
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func changes(_ changes: [ImportPlan.Change]) -> some View {
        ForEach(changes, id: \.path) { change in
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(change.key)
                    .fontWeight(.medium)
                Spacer(minLength: 8)
                if let old = change.old {
                    Text(TOMLWriter.literal(old))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                }
                Text(TOMLWriter.literal(change.new))
            }
            .font(.system(size: Metrics.chromeFontSize, design: .monospaced))
            .lineLimit(1)
        }
    }
}

private struct ThemeRow: View {
    let theme: Theme
    let replaces: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { index in
                    Rectangle().fill(Color(theme.palette[index]))
                }
            }
            .frame(width: 96, height: 14)
            .padding(3)
            .background(Color(theme.background), in: .rect(cornerRadius: 5))
            Text(theme.name)
            Spacer()
            Text(replaces ? "Updates" : "New")
                .font(.caption.weight(.semibold))
                .foregroundStyle(replaces ? Color.secondary : Color.green)
        }
    }
}
