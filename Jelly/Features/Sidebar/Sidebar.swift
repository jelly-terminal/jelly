import JellyCore
import SwiftUI

struct Sidebar: View {
    @Bindable var model: WindowModel
    let theme: Theme
    let backgroundOpacity: Double

    static let animation = Animation.smooth(duration: 0.25)

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sidebarSectionSpacing) {
            HStack {
                Spacer()
                SidebarToggle(model: model, theme: theme)
                    .offset(y: -(Metrics.sidebarInset + Metrics.sidebarPadding) / 2)
            }
            .frame(height: Metrics.tabBarHeight - Metrics.sidebarInset - Metrics.sidebarPadding)
            .background {
                Color.clear
                    .contentShape(.rect)
                    .gesture(WindowDragGesture())
            }

            SidebarSection(title: "Sessions", theme: theme, addHelp: "New Session") {
                withAnimation(Self.animation) { model.newSession() }
            } content: {
                ForEach(model.sessions) { session in
                    SessionRow(model: model, session: session, theme: theme)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Metrics.sidebarPadding)
        .frame(width: Metrics.sidebarWidth)
        .frame(maxHeight: .infinity)
        .background {
            let shape = RoundedRectangle(cornerRadius: Metrics.sidebarCornerRadius, style: .continuous)
            shape
                .fill(Color(theme.background, opacity: backgroundOpacity))
                .overlay(shape.strokeBorder(Color(theme.foreground).opacity(0.1), lineWidth: 1))
        }
        .padding(Metrics.sidebarInset)
    }
}

struct SidebarToggle: View {
    @Bindable var model: WindowModel
    let theme: Theme

    var body: some View {
        Button {
            withAnimation(Sidebar.animation) { model.isSidebarVisible.toggle() }
        } label: {
            Image(systemName: "sidebar.left")
                .frame(width: Metrics.controlSize, height: Metrics.controlSize)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(theme.foreground).opacity(0.6))
        .help(model.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
    }
}

private struct SidebarSection<Content: View>: View {
    let title: String
    let theme: Theme
    let addHelp: String
    let onAdd: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.system(size: Metrics.chromeFontSize, weight: .semibold))
                    .foregroundStyle(Color(theme.foreground).opacity(0.55))
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 20, height: 20)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(theme.foreground).opacity(0.6))
                .help(addHelp)
            }
            .padding(.horizontal, Metrics.sidebarRowPadding)
            .padding(.bottom, 4)
            content()
        }
        .padding(Metrics.sidebarSectionPadding)
        .background(Color(theme.foreground).opacity(0.04), in: .rect(cornerRadius: Metrics.sidebarSectionCornerRadius))
    }
}

private struct SessionRow: View {
    @Bindable var model: WindowModel
    let session: SessionModel
    let theme: Theme

    @State private var isHovered = false
    @State private var draft = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        let isSelected = session.id == model.selectedSessionID
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "rectangle.stack.fill" : "rectangle.stack")
                .foregroundStyle(isSelected ? Color(theme.accent) : Color(theme.foreground).opacity(0.5))
                .frame(width: 16)
            if model.renamingSessionID == session.id {
                TextField("Name", text: $draft)
                    .textFieldStyle(.plain)
                    .focused($isEditing)
                    .onSubmit { model.rename(session, to: draft) }
                    .onExitCommand { model.cancelRename() }
                    .onAppear {
                        draft = session.name
                        DispatchQueue.main.async { isEditing = true }
                    }
                    .onChange(of: isEditing) { _, editing in
                        if !editing, model.renamingSessionID == session.id { model.rename(session, to: draft) }
                    }
            } else {
                Text(session.name)
                    .lineLimit(1)
                    .foregroundStyle(Color(theme.foreground).opacity(isSelected ? 1 : 0.75))
            }
            Spacer(minLength: 4)
            if let tone = session.workspace.agentTone, tone != .ready {
                AgentIndicator(tone: tone, theme: theme)
            }
            if session.tabCount > 0 {
                Text("\(session.tabCount)")
                    .monospacedDigit()
                    .font(.system(size: Metrics.statusFontSize))
                    .foregroundStyle(Color(theme.foreground).opacity(0.4))
            }
        }
        .font(.system(size: Metrics.chromeFontSize + 0.5))
        .padding(.horizontal, Metrics.sidebarRowPadding)
        .frame(height: Metrics.sidebarRowHeight)
        .background(rowBackground(isSelected: isSelected), in: .rect(cornerRadius: Metrics.sidebarRowCornerRadius))
        .contentShape(.rect)
        .onTapGesture { model.select(session) }
        .simultaneousGesture(TapGesture(count: 2).onEnded { model.renamingSessionID = session.id })
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Rename") { model.renamingSessionID = session.id }
            Button("Delete", role: .destructive) { withAnimation(Sidebar.animation) { model.requestDelete(session) } }
                .disabled(model.sessions.count < 2)
        }
    }

    private func rowBackground(isSelected: Bool) -> Color {
        if isSelected { return Color(theme.accent).opacity(0.22) }
        return isHovered ? Color(theme.foreground).opacity(0.06) : .clear
    }
}
