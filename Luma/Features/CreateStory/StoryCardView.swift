import SwiftUI

struct StoryCardView: View {
    let story: StoryModel
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.headline)
                .foregroundColor(LumaTheme.text)
                .lineLimit(1)
            Text(story.content)
                .font(.subheadline)
                .foregroundColor(LumaTheme.secondaryText)
                .lineLimit(2)
            HStack {
                Text(dateString)
                Spacer()
                Text(story.theme)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(LumaTheme.lavender.opacity(0.1))
                    .cornerRadius(4)
            }
            .font(.caption)
            .foregroundColor(LumaTheme.secondaryText.opacity(0.8))
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: LumaTheme.lavender.opacity(0.1), radius: 6, x: 0, y: 2)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(LumaTheme.lavender.opacity(0.2), lineWidth: 1))
        .onTapGesture(perform: onTap)
    }

    private var dateString: String {
        guard let date = story.created_at else { return "Yeni" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
