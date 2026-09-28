import AppKit
import SwiftUI

struct MarkdownFlowView: View {
    let flow: MarkdownFlow
    let style: MarkdownStyle

    @State private var rects: [Int: CGRect] = [:]
    @State private var hoveredCode: Int?
    @State private var copiedCode: Int?

    var body: some View {
        SelectableText(
            text: flow.text,
            decorations: flow.decorations,
            linkColor: NSColor(style.accent),
            anchors: anchors
        ) { measured in
            if measured != rects { rects = measured }
        }
        .overlay(alignment: .topLeading) {
            ForEach(flow.anchors.keys.sorted(), id: \.self) { index in
                Color.clear
                    .frame(width: 1, height: 1)
                    .id(index)
                    .padding(.top, rects[index]?.minY ?? 0)
            }
        }
        .overlay(alignment: .topTrailing) {
            ForEach(flow.codeBlocks.indices, id: \.self) { index in
                if let rect = rects[codeKey(index)] {
                    codeBadge(flow.codeBlocks[index], index: index)
                        .padding(.top, rect.minY - Metrics.markdownCodePadding + 6)
                        .padding(.trailing, 6)
                }
            }
        }
        .onContinuousHover { phase in
            guard case .active(let location) = phase else {
                hoveredCode = nil
                return
            }
            let padding = Metrics.markdownCodePadding
            hoveredCode = flow.codeBlocks.indices.first { index in
                guard let rect = rects[codeKey(index)] else { return false }
                return location.y >= rect.minY - padding && location.y <= rect.maxY + padding
            }
        }
    }

    private var anchors: [Int: NSRange] {
        var anchors = flow.anchors
        for (index, block) in flow.codeBlocks.enumerated() { anchors[codeKey(index)] = block.range }
        return anchors
    }

    private func codeKey(_ index: Int) -> Int {
        -1 - index
    }

    @ViewBuilder
    private func codeBadge(_ block: MarkdownFlow.CodeBlock, index: Int) -> some View {
        if hoveredCode == index {
            Button {
                copy(block.text, index: index)
            } label: {
                Image(systemName: copiedCode == index ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .frame(width: Metrics.paneButtonSize, height: Metrics.paneButtonSize)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(style.secondary)
            .help("Copy")
        } else if let language = block.language {
            Text(language)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(style.secondary)
                .frame(height: Metrics.paneButtonSize)
                .allowsHitTesting(false)
        }
    }

    private func copy(_ text: String, index: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedCode = index
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if copiedCode == index { copiedCode = nil }
        }
    }
}
