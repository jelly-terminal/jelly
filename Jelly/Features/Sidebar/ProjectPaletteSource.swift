import Foundation

struct ProjectPaletteSource: PaletteSource {
    let section = "Projects"

    func items(in window: WindowModel) -> [PaletteItem] {
        window.projects.projects.map { project in
            PaletteItem(
                id: "project:" + project.path,
                title: project.name,
                subtitle: (project.path as NSString).abbreviatingWithTildeInPath,
                symbol: "folder",
                keywords: ["Project " + project.name, project.path]
            ) {
                window.open(project)
            }
        }
    }
}
