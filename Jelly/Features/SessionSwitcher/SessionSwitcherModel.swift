import AppKit
import Observation

@Observable
final class SessionSwitcherModel {
    let sessions: [SessionModel]
    let heldModifiers: NSEvent.ModifierFlags
    private(set) var selectedIndex: Int
    var isVisible = false

    static let revealDelay: TimeInterval = 0.12

    init(sessions: [SessionModel], selectedIndex: Int, heldModifiers: NSEvent.ModifierFlags) {
        self.sessions = sessions
        self.selectedIndex = selectedIndex
        self.heldModifiers = heldModifiers
    }

    var selected: SessionModel {
        sessions[selectedIndex]
    }

    func move(by offset: Int) {
        selectedIndex = (selectedIndex + offset + sessions.count) % sessions.count
    }

    func select(_ index: Int) {
        guard sessions.indices.contains(index) else { return }
        selectedIndex = index
    }
}
