import JellyCore
import JellyTerminal
import SwiftUI

struct RootView: View {
    @Bindable var model: WindowModel
    let configStore: ConfigStore
    let license: LicenseService

    var body: some View {
        let theme = configStore.theme
        let settings = configStore.settings
        let workspace = model.workspace

        HStack(spacing: 0) {
            if model.isSidebarVisible {
                Sidebar(model: model, projects: model.projects, theme: theme, backgroundOpacity: settings.window.backgroundOpacity)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if !model.isSidebarVisible {
                        SidebarToggle(model: model, theme: theme)
                            .padding(.leading, Metrics.trafficLightInset)
                    }
                    TabBar(
                        workspace: workspace,
                        theme: theme,
                        leadingInset: model.isSidebarVisible ? Metrics.chromePadding / 2 : Metrics.tabSpacing,
                        onClose: { workspace.requestClose($0, in: model.window) },
                        onFind: { workspace.selectedTab?.surface.showFind() }
                    )
                }
                .background {
                    Color.clear
                        .contentShape(.rect)
                        .gesture(WindowDragGesture())
                }

                ZStack(alignment: .top) {
                    PaneArea(model: model, theme: theme, settings: settings)
                        .padding(.horizontal, Metrics.chromePadding)
                        .padding(.bottom, settings.window.statusBar ? 0 : Metrics.chromePadding)

                    if workspace.tabs.isEmpty {
                        EmptySessionView(theme: theme) {
                            withAnimation(TabBar.animation) { _ = workspace.newTab() }
                        }
                    }

                    VStack(spacing: 8) {
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
                }
                .animation(.smooth, value: configStore.visibleDiagnostics.count)

                if settings.window.statusBar {
                    StatusBar(
                        sessionName: model.selectedSession.name,
                        tabCount: workspace.tabs.count,
                        paneCount: workspace.selectedTab?.panes.count ?? 0,
                        gridSize: workspace.selectedTab?.gridSize,
                        theme: theme
                    )
                }
            }
        }
        .background {
            WindowBackground(
                color: theme.background,
                opacity: settings.window.backgroundOpacity,
                blur: settings.window.blur,
                shade: theme.appearance == .dark ? 0.3 : 0.05
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
        .sheet(isPresented: $model.isLicenseSheetPresented) {
            LicenseSheet(
                license: license,
                dismissTitle: "Cancel",
                onActivated: { model.isLicenseSheetPresented = false },
                onDismiss: { model.isLicenseSheetPresented = false }
            )
        }
    }
}

private struct EmptySessionView: View {
    let theme: Theme
    let onNewTab: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.system(size: 28))
                .foregroundStyle(Color(theme.foreground).opacity(0.3))
            Text("No open tabs")
                .foregroundStyle(Color(theme.foreground).opacity(0.5))
            Button("New Tab", action: onNewTab)
                .buttonStyle(.glass)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
