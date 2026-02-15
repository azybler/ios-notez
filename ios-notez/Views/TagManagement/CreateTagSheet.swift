import SwiftUI

struct CreateTagSheet: View {
    @State private var name = ""
    @State private var color: String? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $name)
                }

                Section {
                    ColorPickerGridView(selectedColor: $color)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTag()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createTag() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        do {
            try AppDatabase.shared.writer.write { db in
                var tag = Tag(name: trimmedName, color: color)
                try GRDBTagRepository().save(&tag, db: db)
            }
        } catch {}
    }
}
