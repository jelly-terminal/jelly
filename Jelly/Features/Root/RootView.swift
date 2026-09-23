import JellyCore
import JellyTerminal
import SwiftUI

struct RootView: View {
    @Bindable var model: WindowModel
    let configStore: ConfigStore

    var body: some View {
        let theme = configStore.theme
        let settings = configStore.settings
        let workspace = model.workspace

        VStack(spacing: 0) {
            TabBar(
                workspace: workspace,
                theme: theme,
                onClose: { workspace.requestClose($0, in: model.window) },
                onFind: { workspace.selectedTab?.surface.showFind() }
            )
            .background {
                Color.clear
                    .contentShape(.rect)
                    .gesture(WindowDragGesture())
            }

            ZStack(alignment: .top) {
                TerminalHost(surfaces: workspace.tabs.map(\.surface), selected: workspace.selectedTab?.surface)
                    .padding(.horizontal, settings.window.paddingX)
                    .padding(.vertical, settings.window.paddingY)

                let diagnostics = configStore.visibleDiagnostics
                if !diagnostics.isEmpty {
                    DiagnosticsBanner(
                        diagnostics: diagnostics,
                        onOpenConfig: configStore.openConfigFile,
                        onDismiss: { configStore.dismissedDiagnostics += diagnostics }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.smooth, value: configStore.visibleDiagnostics.count)

            if settings.window.statusBar {
                StatusBar(tab: workspace.selectedTab, tabCount: workspace.tabs.count, theme: theme)
            }
        }
        .background {
            WindowBackground(
                color: theme.background,
                opacity: settings.window.backgroundOpacity,
                blur: settings.window.blur
            )
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, theme.appearance == .dark ? .dark : .light)
        .tint(Color(theme.accent))
        .dropDestination(for: URL.self) { urls, _ in model.handleDrop(urls) }
        .sheet(item: $model.pendingImport) { pending in
            ImportSheet(
                pending: pending,
                onImport: model.confirmImport,
                onInsertPath: model.insertPendingPath,
                onCancel: { model.pendingImport = nil }
            )
        }
        .alert("Import", isPresented: Binding(get: { model.importError != nil }, set: { if !$0 { model.importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.importError ?? "")
        }
    }
}
