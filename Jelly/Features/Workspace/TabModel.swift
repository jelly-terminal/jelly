import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class TabModel: Identifiable {
    let id = UUID()
    var customTitle: String?
    private(set) var layout: PaneTree
    private(set) var panes: [PaneID: PaneModel]
    private(set) var focusedPaneID: PaneID
    private(set) var zoomedPaneID: PaneID?

    init(panes: [PaneModel], layout: PaneTree, focused: PaneID? = nil) {
        self.layout = layout
        self.panes = Dictionary(uniqueKeysWithValues: panes.map { ($0.id, $0) })
        focusedPaneID = focused.flatMap { layout.contains($0) ? $0 : nil } ?? layout.panes[0]
    }

    convenience init(pane: PaneModel) {
        self.init(panes: [pane], layout: .leaf(pane.id))
    }

    var orderedPanes: [PaneModel] {
        layout.panes.compactMap { panes[$0] }
    }

    var focusedPane: PaneModel {
        panes[focusedPaneID] ?? orderedPanes[0]
    }

    var surface: TerminalSurface {
        focusedPane.surface
    }

    var displayTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        return focusedPane.displayTitle
    }

    var gridSize: (cols: Int, rows: Int) {
        focusedPane.gridSize
    }

    var hasForegroundProcess: Bool {
        panes.values.contains { $0.surface.hasForegroundProcess }
    }

    func focus(_ pane: PaneID) {
        guard panes[pane] != nil, pane != focusedPaneID else { return }
        if zoomedPaneID != nil { zoomedPaneID = pane }
        focusedPaneID = pane
    }

    func focus(toward direction: KeyAction.Direction) {
        zoomedPaneID = nil
        if let neighbor = layout.neighbor(of: focusedPaneID, toward: direction) {
            focusedPaneID = neighbor
        }
    }

    func insert(_ pane: PaneModel, splitting target: PaneID, axis: PaneTree.Axis) {
        panes[pane.id] = pane
        layout = layout.splitting(target, axis: axis, with: pane.id)
        zoomedPaneID = nil
        focusedPaneID = pane.id
    }

    func remove(_ pane: PaneID) {
        let order = layout.panes
        guard let remaining = layout.removing(pane), let index = order.firstIndex(of: pane) else { return }
        layout = remaining
        panes[pane] = nil
        if zoomedPaneID == pane { zoomedPaneID = nil }
        if focusedPaneID == pane {
            focusedPaneID = remaining.panes[max(0, index - 1)]
        }
    }

    func setRatio(_ ratio: Double, forSplit split: UUID) {
        layout = layout.settingRatio(ratio, forSplit: split)
    }

    func equalize() {
        layout = layout.equalized()
    }

    func toggleZoom() {
        guard panes.count > 1 else { return }
        zoomedPaneID = zoomedPaneID == nil ? focusedPaneID : nil
    }

    func stop() {
        panes.values.forEach { $0.surface.stop() }
    }

    var snapshot: WorkspaceSnapshot.Tab {
        WorkspaceSnapshot.Tab(
            directory: surface.workingDirectory,
            customTitle: customTitle,
            layout: layout,
            panes: orderedPanes.map { WorkspaceSnapshot.Pane(id: $0.id, directory: $0.surface.workingDirectory) },
            focusedPane: focusedPaneID
        )
    }
}
