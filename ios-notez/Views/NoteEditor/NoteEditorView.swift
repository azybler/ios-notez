import SwiftUI
import MarkdownUI

struct NoteEditorView: View {
    @State private var viewModel: NoteEditorViewModel
    @State private var showPreview = false
    @State private var showFolderPicker = false
    @State private var showTagPicker = false
    @Environment(\.dismiss) private var dismiss

    init(noteId: Int64?, folderId: Int64?) {
        self._viewModel = State(initialValue: NoteEditorViewModel(noteId: noteId, folderId: folderId))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                titleField
                Divider().padding(.horizontal).padding(.vertical, 4)
                metadataBar
                Divider().padding(.vertical, 4)

                if showPreview {
                    ScrollView {
                        Markdown(viewModel.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    MarkdownToolbar(text: $viewModel.body)
                    TextEditor(text: $viewModel.body)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .onChange(of: viewModel.body) { _, _ in viewModel.save() }
                }
            }
            .navigationTitle(viewModel.isNew ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        viewModel.saveImmediately()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPreview.toggle()
                    } label: {
                        Image(systemName: showPreview ? "pencil" : "eye")
                    }
                }
            }
            .sheet(isPresented: $showFolderPicker) {
                FolderPickerSheet(selectedFolderId: $viewModel.folderId, folders: viewModel.allFolders)
                    .onDisappear { viewModel.save() }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerSheet(selectedTagIds: $viewModel.selectedTagIds, tags: viewModel.allTags)
                    .onDisappear { viewModel.save() }
            }
        }
    }

    private var titleField: some View {
        TextField("Title", text: $viewModel.title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: viewModel.title) { _, _ in viewModel.save() }
    }

    private var metadataBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                folderButton
                tagButton
                pinButton
            }
            .padding(.horizontal)
        }
    }

    private var folderButton: some View {
        Button {
            showFolderPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder").font(.caption)
                Text(folderName).font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var tagButton: some View {
        Button {
            showTagPicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "tag").font(.caption)
                Text(tagSummary).font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var pinButton: some View {
        Button {
            viewModel.isPinned.toggle()
            viewModel.save()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isPinned ? "pin.fill" : "pin").font(.caption)
                Text(viewModel.isPinned ? "Pinned" : "Pin").font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(viewModel.isPinned ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.12))
            .foregroundStyle(viewModel.isPinned ? .orange : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var folderName: String {
        if let folderId = viewModel.folderId,
           let folder = viewModel.allFolders.first(where: { $0.id == folderId }) {
            return folder.name
        }
        return "No Folder"
    }

    private var tagSummary: String {
        if viewModel.selectedTagIds.isEmpty { return "No Tags" }
        let selectedTags = viewModel.allTags.filter { viewModel.selectedTagIds.contains($0.id!) }
        if selectedTags.count == 1 { return selectedTags[0].name }
        return "\(selectedTags.count) tags"
    }
}

// MARK: - Folder Picker

struct FolderPickerSheet: View {
    @Binding var selectedFolderId: Int64?
    let folders: [Folder]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedFolderId = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("No Folder (Unsorted)")
                        Spacer()
                        if selectedFolderId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(folders) { folder in
                    Button {
                        selectedFolderId = folder.id
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: folder.parentFolderId == nil ? "folder.fill" : "folder")
                                .foregroundStyle(Color(hex: folder.color) ?? .blue)
                            Text(folder.name)
                                .padding(.leading, folder.parentFolderId != nil ? 16 : 0)
                            Spacer()
                            if selectedFolderId == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Tag Picker

struct TagPickerSheet: View {
    @Binding var selectedTagIds: Set<Int64>
    let tags: [Tag]
    @State private var newTagName = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("New tag name", text: $newTagName)
                        Button("Add") {
                            createTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                Section {
                    ForEach(tags) { tag in
                        tagRow(tag)
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        Button {
            if let id = tag.id {
                if selectedTagIds.contains(id) {
                    selectedTagIds.remove(id)
                } else {
                    selectedTagIds.insert(id)
                }
            }
        } label: {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Color(hex: tag.color) ?? .blue)
                Text(tag.name)
                Spacer()
                if let id = tag.id, selectedTagIds.contains(id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            try AppDatabase.shared.writer.write { db in
                var tag = Tag(name: name)
                try tag.insert(db)
                if let id = tag.id {
                    selectedTagIds.insert(id)
                }
            }
            newTagName = ""
        } catch {}
    }
}
