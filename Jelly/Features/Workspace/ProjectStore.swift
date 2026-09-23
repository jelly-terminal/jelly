import Foundation
import JellyCore
import Observation
import SwiftUI

@Observable
final class ProjectStore {
    struct Project: Identifiable, Equatable {
        var path: String
        var name: String
        var id: String { path }
    }

    private(set) var projects: [Project]

    init(_ snapshot: [WorkspaceSnapshot.Project] = []) {
        projects = snapshot.map { Project(path: $0.path, name: $0.name) }
    }

    var snapshot: [WorkspaceSnapshot.Project] {
        projects.map { WorkspaceSnapshot.Project(path: $0.path, name: $0.name) }
    }

    func add(_ urls: [URL]) {
        for url in urls {
            var isDirectory: ObjCBool = false
            let path = url.path(percentEncoded: false)
            guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue,
                  !projects.contains(where: { $0.path == path })
            else { continue }
            projects.append(Project(path: path, name: url.lastPathComponent))
        }
    }

    func remove(_ project: Project) {
        projects.removeAll { $0 == project }
    }

    func move(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
    }
}
