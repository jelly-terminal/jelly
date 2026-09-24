import JellyCore
import SwiftUI

struct PaletteView: View {
    @Bindable var palette: PaletteModel
    let theme: Theme
    let onClose: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                field
                if !palette.matches.isEmpty {
                    separator
                    list
                } else if palette.isFiltering {
                    separator
                    Text("No matches")
                        .font(.system(size: Metrics.chromeFontSize))
                        .foregroundStyle(foreground.opacity(0.5))
                        .frame(height: Metrics.paletteRowHeight * 2)
                }
            }
            .frame(width: Metrics.paletteWidth)
            .background {
                let shape = RoundedRectangle(cornerRadius: Metrics.paletteCornerRadius, style: .continuous)
                shape
                    .fill(Color(theme.background))
                    .overlay(shape.strokeBorder(foreground.opacity(0.12), lineWidth: 1))
            }
            .clipShape(.rect(cornerRadius: Metrics.paletteCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
            .padding(.top, Metrics.paletteTopInset)
        }
        .onAppear { isFieldFocused = true }
    }

    private var foreground: Color {
        Color(theme.foreground)
    }

    private var separator: some View {
        Rectangle().fill(foreground.opacity(0.08)).frame(height: 1)
    }

    private var field: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Metrics.paletteFieldFontSize))
                .foregroundStyle(foreground.opacity(0.5))
            TextField("Search actions, tabs, sessions, projects, themes", text: $palette.query)
                .textFieldStyle(.plain)
                .font(.system(size: Metrics.paletteFieldFontSize))
                .foregroundStyle(foreground)
                .focused($isFieldFocused)
        }
        .padding(.horizontal, 14)
        .frame(height: Metrics.paletteFieldHeight)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(palette.matches.enumerated()), id: \.element.id) { index, match in
                        if !palette.isFiltering, index == 0 || palette.matches[index - 1].section != match.section {
                            sectionHeader(match.section)
                        }
                        PaletteRow(match: match, isSelected: match.id == palette.selectedID, foreground: foreground, accent: Color(theme.accent))
                            .id(match.id)
                            .onTapGesture { palette.run(match.item) }
                    }
                }
                .padding(Metrics.palettePadding)
            }
            .frame(height: min(listContentHeight, Metrics.paletteListHeight))
            .onChange(of: palette.selectedID) { _, id in
                guard let id else { return }
                proxy.scrollTo(id)
            }
        }
    }

    private var listContentHeight: CGFloat {
        let matches = palette.matches
        let sections = palette.isFiltering ? 0 : zip(matches, matches.dropFirst()).count { $0.section != $1.section } + 1
        return CGFloat(matches.count) * Metrics.paletteRowHeight
            + CGFloat(sections) * Metrics.paletteSectionHeight
            + Metrics.palettePadding * 2
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Metrics.statusFontSize, weight: .semibold))
            .foregroundStyle(foreground.opacity(0.45))
            .padding(.horizontal, 10)
            .frame(height: Metrics.paletteSectionHeight, alignment: .bottomLeading)
    }
}
