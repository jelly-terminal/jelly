import SwiftUI

struct ImageFileView: View {
    let image: CGImage
    let style: MarkdownStyle

    @State private var actualSize = false
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        let size = CGSize(width: CGFloat(image.width) / displayScale, height: CGFloat(image.height) / displayScale)
        let picture = Image(decorative: image, scale: displayScale)
            .resizable()
            .interpolation(.high)
        ZStack(alignment: .bottom) {
            if actualSize {
                ScrollView([.horizontal, .vertical]) {
                    picture.frame(width: size.width, height: size.height)
                }
            } else {
                picture
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: size.width, maxHeight: size.height)
                    .padding(Metrics.viewerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Text("\(image.width) × \(image.height)")
                .font(.system(size: Metrics.chromeFontSize).monospacedDigit())
                .foregroundStyle(style.secondary)
                .padding(.bottom, 8)
        }
        .contentShape(.rect)
        .onTapGesture(count: 2) { actualSize.toggle() }
        .help("Double-click to toggle actual size")
    }
}
