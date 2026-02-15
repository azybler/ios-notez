import SwiftUI

struct EditTagSheet: View {
    @State private var name: String
    @State private var color: String?
    @State private var showDeleteAlert = false
    @State private var showMergeSheet = false
    @State private var showMergeHistory = false
    @State private var noteCount = 0
    let tag: Tag
    let onDismiss: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    init(tag: Tag, onDismiss: @escaping (Bool) -> Void) {
        self.tag = tag
        self.onDismiss = onDismiss
        self._name = State(initialValue: tag.name)
        self._color = State(initialValue: tag.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $name)
                }

                Section {
                    ColorPickerGridView(selectedColor: $color)
                }

                Section {
                    Button {
                        showMergeSheet = true
                    } label: {
                        Label("Merge Other Tags Into This", systemImage: "arrow.triangle.merge")
                    }

                    Button {
                        showMergeHistory = true
                    } label: {
                        Label("Merge History", systemImage: "clock.arrow.circlepath")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        loadNoteCount()
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Tag", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss(false)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTag()
                        onDismiss(false)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Tag?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteTag()
                    onDismiss(true)
                    dismiss()
                }
            } message: {
                Text("This will remove the tag from \(noteCount) note(s). This cannot be undone. Consider merging into another tag instead.")
            }
            .sheet(isPresented: $showMergeSheet) {
                MergeTagsSheet(targetTag: tag)
            }
            .sheet(isPresented: $showMergeHistory) {
                MergeHistoryView(targetTag: tag)
            }
        }
    }

    private func loadNoteCount() {
        do {
            try AppDatabase.shared.reader.read { db in
                noteCount = try GRDBNoteRepository().countByTag(tagId: tag.id!, db: db)
            }
        } catch {}
    }

    private func saveTag() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        do {
            try AppDatabase.shared.writer.write { db in
                var updated = tag
                updated.name = trimmedName
                updated.color = color
                try GRDBTagRepository().save(&updated, db: db)
            }
        } catch {}
    }

    private func deleteTag() {
        do {
            try AppDatabase.shared.writer.write { db in
                try GRDBTagRepository().delete(id: tag.id!, db: db)
            }
        } catch {}
    }
}
