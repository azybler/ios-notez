import SwiftUI

struct MergeTagsSheet: View {
    let targetTag: Tag
    @State private var allTags: [TagWithCount] = []
    @State private var selectedSourceIds: Set<Int64> = []
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

    private var availableTags: [TagWithCount] {
        allTags.filter { $0.tag.id != targetTag.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Select tags to merge into **\(targetTag.name)**.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Available Tags") {
                    ForEach(availableTags, id: \.tag.id) { tagWithCount in
                        mergeTagRow(tagWithCount)
                    }
                }
            }
            .navigationTitle("Merge Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Merge") {
                        showConfirmation = true
                    }
                    .disabled(selectedSourceIds.isEmpty)
                }
            }
            .alert("Merge Tags?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Merge") {
                    mergeTags()
                    dismiss()
                }
            } message: {
                Text("You can undo this later from the merge history.")
            }
            .onAppear { loadTags() }
        }
    }

    private func mergeTagRow(_ tagWithCount: TagWithCount) -> some View {
        let tagId = tagWithCount.tag.id!
        let isSelected = selectedSourceIds.contains(tagId)
        return Button {
            if isSelected {
                selectedSourceIds.remove(tagId)
            } else {
                selectedSourceIds.insert(tagId)
            }
        } label: {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Color(hex: tagWithCount.tag.color) ?? .blue)
                Text(tagWithCount.tag.name)
                Spacer()
                Text("\(tagWithCount.noteCount)")
                    .foregroundStyle(.secondary)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func loadTags() {
        do {
            try AppDatabase.shared.reader.read { db in
                allTags = try GRDBTagRepository().fetchAllWithCounts(db: db)
            }
        } catch {}
    }

    private func mergeTags() {
        do {
            try AppDatabase.shared.writer.write { db in
                try GRDBTagRepository().merge(
                    sourceTagIds: Array(selectedSourceIds),
                    targetTagId: targetTag.id!,
                    db: db
                )
            }
        } catch {}
    }
}
