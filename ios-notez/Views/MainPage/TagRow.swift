import SwiftUI

struct TagRow: View {
    let tagWithCount: TagWithCount

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: tagWithCount.tag.color) ?? .accentColor)
                .frame(width: 28)

            Text(tagWithCount.tag.name)
                .font(.body)

            Spacer()

            Text("\(tagWithCount.noteCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
