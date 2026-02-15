import SwiftUI

struct EditFolderSheet: View {
    @State private var name: String
    @State private var color: String?
    @State private var showDeleteAlert = false
    @State private var noteCount = 0
    let folder: Folder
    let onDismiss: (Bool) -> Void  // true if deleted
    @Environment(\.dismiss) private var dismiss

    init(folder: Folder, onDismiss: @escaping (Bool) -> Void) {
        self.folder = folder
        self.onDismiss = onDismiss
        self._name = State(initialValue: folder.name)
        self._color = State(initialValue: folder.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder name", text: $name)
                }

                Section {
                    ColorPickerGridView(selectedColor: $color)
                }

                Section {
                    Button(role: .destructive) {
                        loadNoteCount()
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Folder", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit Folder")
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
                        saveFolder()
                        onDismiss(false)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Folder?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteFolder()
                    onDismiss(true)
                    dismiss()
                }
            } message: {
                Text("\(noteCount) note(s) will be moved to Unsorted Notes. Subfolders will become top-level folders.")
            }
        }
    }

    private func loadNoteCount() {
        do {
            try AppDatabase.shared.reader.read { db in
                noteCount = try GRDBNoteRepository().countByFolder(folderId: folder.id!, db: db)
            }
        } catch {}
    }

    private func saveFolder() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        do {
            try AppDatabase.shared.writer.write { db in
                var updated = folder
                updated.name = trimmedName
                updated.color = color
                try GRDBFolderRepository().save(&updated, db: db)
            }
        } catch {}
    }

    private func deleteFolder() {
        do {
            try AppDatabase.shared.writer.write { db in
                try GRDBFolderRepository().delete(id: folder.id!, db: db)
            }
        } catch {}
    }
}
