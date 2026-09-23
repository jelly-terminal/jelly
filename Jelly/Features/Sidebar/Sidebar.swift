import AppKit
import JellyCore
import SwiftUI

struct Sidebar: View {
    @Bindable var model: WindowModel
    let projects: ProjectStore
    let theme: Theme

    static let animation = Animation.smooth(duration: 0.25)

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sidebarSectionSpacing) {
            HStack {
                Spacer()
                SidebarToggle(model: model, theme: theme)
            }
            .frame(height: Metrics.tabBarHeight - Metrics.sidebarInset)

            SidebarSection(title: "Sessions", theme: theme, addHelp: "New Session") {
                withAnimation(Self.animation) { model.newSession() }
            } content: {
                ForEach(model.sessions) { session in
                    SessionRow(model: model, session: session, theme: theme)
                }
            }

            SidebarSection(title: "Projects", theme: theme, addHelp: "Add Project Folder", onAdd: addProject) {
                if projects.projects.isEmpty {
                    Text("Drop folders here")
                        .font(.system(size: Metrics.chromeFontSize))
                        .foregroundStyle(Color(theme.foreground).opacity(0.4))
                        .padding(.horizontal, Metrics.sidebarRowPadding)
                        .padding(.vertical, 4)
                }
                ForEach(projects.projects) { project in
                    ProjectRow(project: project, theme: theme, onOpen: { model.open(project) }, onRemove: {
                        withAnimation(Self.animation) { projects.remove(project) }
                    })
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                withAnimation(Self.animation) { projects.add(urls) }
                return true
            }

            Spacer(minLength: 0)
        }
        .padding(Metrics.sidebarPadding)
        .frame(width: Metrics.sidebarWidth)
        .frame(maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: Metrics.sidebarCornerRadius))
        .padding(Metrics.sidebarInset)
    }

    private func addProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        guard panel.runModal() == .OK else { return }
        withAnimation(Self.animation) { projects.add(panel.urls) }
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
                    .onExitCommand { model.renamingSessionID = nil }
                    .onAppear {
                        draft = session.name
                        isEditing = true
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
            if !session.workspace.tabs.isEmpty {
                Text("\(session.workspace.tabs.count)")
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
        .onTapGesture(count: 2) { model.renamingSessionID = session.id }
        .onTapGesture { model.select(session) }
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

private struct ProjectRow: View {
    let project: ProjectStore.Project
    let theme: Theme
    let onOpen: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder")
                .foregroundStyle(Color(theme.foreground).opacity(0.5))
                .frame(width: 16)
            Text(project.name)
                .lineLimit(1)
                .foregroundStyle(Color(theme.foreground).opacity(0.75))
            Spacer(minLength: 0)
        }
        .font(.system(size: Metrics.chromeFontSize + 0.5))
        .padding(.horizontal, Metrics.sidebarRowPadding)
        .frame(height: Metrics.sidebarRowHeight)
        .background(isHovered ? Color(theme.foreground).opacity(0.06) : .clear, in: .rect(cornerRadius: Metrics.sidebarRowCornerRadius))
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .onHover { isHovered = $0 }
        .help(project.path)
        .contextMenu {
            Button("Open in New Tab", action: onOpen)
            Button("Show in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: project.path)
            }
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
    }
}
