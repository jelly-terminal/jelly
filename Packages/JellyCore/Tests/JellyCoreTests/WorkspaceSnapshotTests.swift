import Foundation
import Testing
@testable import JellyCore

struct WorkspaceSnapshotTests {
    @Test func singleWindowFileLoadsAsOneWindow() throws {
        let json = """
        {"sessions":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Default","tabs":[],"selectedTab":0}],
         "selectedSession":"6F9619FF-8B86-D011-B42D-00C04FC964FF","sidebarVisible":false,
         "projects":[{"path":"/tmp","name":"tmp"}]}
        """
        let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data(json.utf8))
        #expect(snapshot.windows.count == 1)
        #expect(snapshot.windows[0].sessions.map(\.name) == ["Default"])
        #expect(snapshot.windows[0].selectedSession == snapshot.windows[0].sessions[0].id)
        #expect(snapshot.windows[0].sidebarVisible == false)
        #expect(snapshot.projects.map(\.name) == ["tmp"])
    }

    @Test func emptyFileLoadsWithNoWindows() throws {
        let snapshot = try JSONDecoder().decode(WorkspaceSnapshot.self, from: Data("{}".utf8))
        #expect(snapshot.windows.isEmpty)
    }
}
