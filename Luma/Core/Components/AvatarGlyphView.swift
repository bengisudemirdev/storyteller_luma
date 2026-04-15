import SwiftUI

struct AvatarGlyphView: View {
    let emoji: String
    var size: CGFloat
    var color: Color = .primary

    private var safeEmoji: String {
        ChildModel.sanitizeAvatarEmoji(emoji)
    }

    var body: some View {
        Text(safeEmoji)
            .font(.system(size: size))
            .foregroundStyle(color)
            .accessibilityLabel("Avatar emojisi")
    }
}
