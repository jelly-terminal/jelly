import AppKit
import JellyCore
import SwiftUI

struct WindowBackground: View {
    let color: ThemeColor
    let opacity: Double
    let blur: Int
    let shade: Double

    var body: some View {
        ZStack {
            if opacity < 1, blur > 0 {
                BehindWindowBlur(radius: blur)
            }
            Color(color, opacity: opacity)
            Color.black.opacity(shade * opacity)
        }
    }
}

private struct BehindWindowBlur: NSViewRepresentable {
    let radius: Int

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.alphaValue = min(1, CGFloat(radius) / 30)
    }
}
