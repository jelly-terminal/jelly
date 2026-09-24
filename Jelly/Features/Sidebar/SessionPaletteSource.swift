import Foundation


struct SessionPaletteSource: PaletteSource {
    let section = "Sessions"

    func items(in window: WindowModel) -> [PaletteItem] {
        window.sessions.map { session in
            PaletteItem(
                id: "session:" + session.id.uuidString,
                title: session.name,
                subtitle: session.isActivated ? Self.tabCount(session.workspace.tabs.count) : nil,
                symbol: "rectangle.stack",
                keywords: ["Session " + session.name],
                isCurrent: session.id == window.selectedSessionID
            ) {
                window.select(session)
            }
        }
    }

    private static func tabCount(_ count: Int) -> String {
        count == 1 ? "1 tab" : "\(count) tabs"
    }
}
