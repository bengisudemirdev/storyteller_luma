import SwiftUI

struct TagLayout: View {
    @Binding var tags: [String]
    var color: Color

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        self.generateContent(in: .infinity)
            .frame(height: totalHeight)
    }

    private func generateContent(in availableWidth: CGFloat) -> some View {
        return GeometryReader { geo in
            self.content(in: geo.size.width)
        }
    }

    private func content(in width: CGFloat) -> some View {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                TagItem(text: tag, color: color) {
                    // Remove action
                    tags.remove(at: index)
                }
                .alignmentGuide(.leading) { d in
                    if currentX + d.width > width {
                        currentX = 0
                        currentY -= d.height
                    }
                    let result = currentX
                    currentX += d.width
                    return -result
                }
                .alignmentGuide(.top) { d in
                    let result = currentY
                    return -result
                }
            }
        }
        .background(HeightReader(height: $totalHeight))
    }
}

private struct TagItem: View {
    let text: String
    let color: Color
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .foregroundColor(color)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct HeightReader: View {
    @Binding var height: CGFloat

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { value in
            if self.height != value { self.height = value }
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    StatefulPreviewWrapper(["Dinozorlar", "Uzay", "Kediler", "Araba Yarışları", "Masallar"]) { tags in
        VStack(alignment: .leading, spacing: 12) {
            Text("Örnek TagLayout")
            TagLayout(tags: tags, color: .purple)
        }
        .padding()
    }
}

// Helper to preview @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
