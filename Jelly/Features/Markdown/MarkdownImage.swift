import AppKit
import SwiftUI

struct MarkdownImage: View {
    let alt: String
    let source: String
    let style: MarkdownStyle

    @State private var image: NSImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: min(image.size.width, Metrics.markdownMaxWidth), alignment: .leading)
                    .clipShape(.rect(cornerRadius: Metrics.markdownCornerRadius))
            } else if failed {
                Label(alt.isEmpty ? source : alt, systemImage: "photo")
                    .font(style.bodyFont)
                    .foregroundStyle(style.secondary)
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .help(alt)
        .task(id: source) {
            guard let url = URL(string: source, relativeTo: style.baseURL)?.absoluteURL else {
                failed = true
                return
            }
            image = await Self.load(url)
            failed = image == nil
        }
    }

    @concurrent
    private nonisolated static func load(_ url: URL) async -> NSImage? {
        let data: Data?
        if url.isFileURL {
            data = try? Data(contentsOf: url)
        } else {
            data = try? await URLSession.shared.data(from: url).0
        }
        return data.flatMap(NSImage.init(data:))
    }
}
