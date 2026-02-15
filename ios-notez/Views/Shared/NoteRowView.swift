import SwiftUI

struct NoteRowView: View {
    let noteInfo: NoteInfo
    let showSnippets: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if noteInfo.note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(noteInfo.note.title.isEmpty ? "Untitled" : noteInfo.note.title)
                    .font(.body)
                    .fontWeight(noteInfo.note.isPinned ? .semibold : .regular)
                    .lineLimit(1)
                    .foregroundStyle(noteInfo.note.title.isEmpty ? .secondary : .primary)

                Spacer()

                Text(noteInfo.note.modifiedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if showSnippets {
                let snippet = SnippetGenerator.generate(from: noteInfo.note.body)
                if !snippet.isEmpty {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if !noteInfo.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(noteInfo.tags) { tag in
                            TagChipView(tag: tag)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct TagChipView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (Color(hex: tag.color) ?? .accentColor).opacity(0.15)
            )
            .foregroundStyle(Color(hex: tag.color) ?? .accentColor)
            .clipShape(Capsule())
    }
}
