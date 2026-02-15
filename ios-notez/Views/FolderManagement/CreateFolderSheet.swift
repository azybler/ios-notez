import SwiftUI

struct CreateFolderSheet: View {
    @State private var name = ""
    @State private var color: String? = nil
    @State private var parentFolderId: Int64? = nil
    @State private var topLevelFolders: [Folder] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder name", text: $name)
                }

                Section("Parent Folder") {
                    Picker("Parent", selection: $parentFolderId) {
                        Text("None (Top Level)").tag(nil as Int64?)
                        ForEach(topLevelFolders) { folder in
                            Text(folder.name).tag(folder.id as Int64?)
                        }
                    }
                }

                Section {
                    ColorPickerGridView(selectedColor: $color)
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createFolder()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadFolders()
            }
        }
    }

    private func loadFolders() {
        do {
            try AppDatabase.shared.reader.read { db in
                topLevelFolders = try GRDBFolderRepository().fetchTopLevel(db: db)
            }
        } catch {}
    }

    private func createFolder() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        do {
            try AppDatabase.shared.writer.write { db in
                var folder = Folder(name: trimmedName, parentFolderId: parentFolderId, color: color)
                try GRDBFolderRepository().save(&folder, db: db)
            }
        } catch {}
    }
}
