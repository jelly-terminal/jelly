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
                SessionList(model: model, theme: theme)
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

private struct SessionList: View {
    @Bindable var model: WindowModel
    let theme: Theme

    @State private var drag: SessionDrag?

    private static let space = "SessionList"
    private static let slot = Metrics.sidebarRowHeight + Metrics.sidebarRowSpacing

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.sidebarRowSpacing) {
            ForEach(Array(model.sessions.enumerated()), id: \.element.id) { index, session in
                SessionRow(model: model, session: session, theme: theme)
                    .offset(y: dragOffset(at: index))
                    .zIndex(drag?.from == index ? 1 : 0)
                    .highPriorityGesture(reorderGesture(from: index), including: model.renamingSessionID == session.id ? .subviews : .all)
            }
        }
        .coordinateSpace(.named(Self.space))
    }

    private func dragOffset(at index: Int) -> CGFloat {
        guard let drag else { return 0 }
        if index == drag.from { return clampedTranslation(drag) }
        if index > drag.from, index <= drag.index { return -Self.slot }
        if index < drag.from, index >= drag.index { return Self.slot }
        return 0
    }

    private func clampedTranslation(_ drag: SessionDrag) -> CGFloat {
        let upper = CGFloat(model.sessions.count - 1 - drag.from) * Self.slot
        return min(max(drag.translation, -CGFloat(drag.from) * Self.slot), upper)
    }

    private func reorderGesture(from index: Int) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.space))
            .onChanged { value in
                var next = drag ?? SessionDrag(from: index, index: index, translation: 0)
                next.translation = value.translation.height
                let target = next.from + Int((clampedTranslation(next) / Self.slot).rounded())
                next.index = min(max(target, 0), model.sessions.count - 1)
                if next.index != drag?.index {
                    withAnimation(Sidebar.animation) { drag = next }
                } else {
                    drag = next
                }
            }
            .onEnded { _ in
                guard let drag else { return }
                withAnimation(Sidebar.animation) {
                    if drag.index != drag.from {
                        model.moveSessions(from: IndexSet(integer: drag.from), to: drag.index > drag.from ? drag.index + 1 : drag.index)
                    }
                    self.drag = nil
                }
            }
    }
}

private struct SessionDrag {
    let from: Int
    var index: Int
    var translation: CGFloat
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
                .foregroundStyle(session.color.color(theme).opacity(isSelected ? 1 : 0.7))
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
            Picker("Color", selection: Bindable(session).color) {
                ForEach(SessionColor.allCases, id: \.self) { color in
                    Label {
                        Text(color.name)
                    } icon: {
                        Image(nsImage: Self.swatch(color.color(theme)))
                    }
                }
            }
            Button("Delete", role: .destructive) { withAnimation(Sidebar.animation) { model.requestDelete(session) } }
                .disabled(model.sessions.count < 2)
        }
    }

    private static func swatch(_ color: Color) -> NSImage {
        let size = NSSize(width: 12, height: 12)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor(color).setFill()
            NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1)).fill()
            return true
        }
        image.isTemplate = false
        return image
    }

    private func rowBackground(isSelected: Bool) -> Color {
        if isSelected { return Color(theme.accent).opacity(0.22) }
        return isHovered ? Color(theme.foreground).opacity(0.06) : .clear
    }
}
