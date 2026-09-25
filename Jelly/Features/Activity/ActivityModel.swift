import Darwin
import Foundation
import JellyCore
import JellyTerminal
import Observation

@Observable
final class ActivityModel {
    var tab: ActivityTab {
        didSet {
            UserDefaults.standard.set(tab.rawValue, forKey: Self.tabKey)
            if tab == .ports, oldValue != .ports { start() }
        }
    }
    var corner: ActivityCorner {
        didSet { UserDefaults.standard.set(corner.rawValue, forKey: Self.cornerKey) }
    }
    var expandedPanes: Set<PaneID> = []
    private(set) var snapshot: ActivitySnapshot?
    private(set) var history = ActivityHistory()

    @ObservationIgnored private let sampler = ActivitySampler()
    @ObservationIgnored private let roots: () -> [PaneRoot]
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var recordedAt: ContinuousClock.Instant?

    private static let interval = Duration.seconds(2)
    private static let historySpacing = Duration.milliseconds(1500)
    private static let otherLimit = 8
    private static let tabKey = "activity.tab"
    private static let cornerKey = "activity.corner"

    init(roots: @escaping () -> [PaneRoot]) {
        self.roots = roots
        let defaults = UserDefaults.standard
        tab = defaults.string(forKey: Self.tabKey).flatMap(ActivityTab.init(rawValue:)) ?? .processes
        corner = defaults.string(forKey: Self.cornerKey).flatMap(ActivityCorner.init(rawValue:)) ?? .bottomTrailing
        start()
    }

    isolated deinit {
        task?.cancel()
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func toggleExpanded(_ paneID: PaneID) {
        if expandedPanes.remove(paneID) == nil { expandedPanes.insert(paneID) }
    }

    func send(_ signal: Int32, to pid: Int32) {
        guard pid > 1 else { return }
        kill(pid, signal)
        start()
    }

    func send(_ signal: Int32, toGroup group: Int32) {
        guard group > 1 else { return }
        killpg(group, signal)
        start()
    }

    private func start() {
        task?.cancel()
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    private func refresh() async {
        var next = await sampler.sample(panes: roots(), includePorts: tab == .ports, otherLimit: Self.otherLimit)
        guard !Task.isCancelled else { return }
        if next.ports == nil { next.ports = snapshot?.ports }
        snapshot = next
        let now = ContinuousClock.now
        if recordedAt.map({ now - $0 >= Self.historySpacing }) ?? true {
            history.append(next.system)
            if next.system.cpu != nil { recordedAt = now }
        }
    }
}
