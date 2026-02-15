import SwiftUI
import Observation
import GRDB

@Observable
@MainActor
final class FolderDetailViewModel {
    var notes: [NoteInfo] = []
    var subfolders: [Folder] = []
    var folder: Folder?

    private var cancellable: AnyDatabaseCancellable?
    private let folderId: Int64
    private let database: AppDatabase

    init(folderId: Int64, database: AppDatabase = .shared) {
        self.folderId = folderId
        self.database = database
        startObservation()
    }

    private func startObservation() {
        let folderId = self.folderId
        let observation = ValueObservation.tracking { db -> (Folder?, [NoteInfo], [Folder]) in
            let noteRepo = GRDBNoteRepository()
            let folderRepo = GRDBFolderRepository()
            let folder = try folderRepo.fetch(id: folderId, db: db)
            let notes = try noteRepo.fetchByFolder(folderId: folderId, db: db)
            let subfolders = try folderRepo.fetchChildren(parentId: folderId, db: db)
            return (folder, notes, subfolders)
        }

        cancellable = observation.start(in: database.writer) { _ in
        } onChange: { [weak self] (folder, notes, subfolders) in
            self?.folder = folder
            self?.notes = notes
            self?.subfolders = subfolders
        }
    }
}

struct FolderDetailView: View {
    let folderId: Int64
    let folderName: String
    @State private var viewModel: FolderDetailViewModel
    @State private var showCreateNote = false
    @State private var showEditFolder = false
    @Environment(\.dismiss) private var dismiss

    init(folderId: Int64, folderName: String) {
        self.folderId = folderId
        self.folderName = folderName
        self._viewModel = State(initialValue: FolderDetailViewModel(folderId: folderId))
    }

    var body: some View {
        List {
            if !viewModel.subfolders.isEmpty {
                Section("Subfolders") {
                    ForEach(viewModel.subfolders) { subfolder in
                        NavigationLink {
                            FolderDetailView(folderId: subfolder.id!, folderName: subfolder.name)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .foregroundStyle(Color(hex: subfolder.color) ?? .accentColor)
                                Text(subfolder.name)
                            }
                        }
                    }
                }
            }

            if viewModel.notes.isEmpty && viewModel.subfolders.isEmpty {
                EmptyStateView(
                    icon: "folder",
                    title: "No notes",
                    message: "This folder is empty. Create a note to get started."
                )
            } else {
                Section("Notes") {
                    ForEach(viewModel.notes, id: \.note.id) { noteInfo in
                        NavigationLink {
                            NoteEditorView(noteId: noteInfo.note.id, folderId: folderId)
                        } label: {
                            NoteRowView(noteInfo: noteInfo, showSnippets: UserSettings.shared.showSnippets)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                softDelete(noteInfo.note.id!)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                togglePin(noteInfo.note)
                            } label: {
                                Label(
                                    noteInfo.note.isPinned ? "Unpin" : "Pin",
                                    systemImage: noteInfo.note.isPinned ? "pin.slash" : "pin"
                                )
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .navigationTitle(folderName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showCreateNote = true
                    } label: {
                        Label("New Note", systemImage: "square.and.pencil")
                    }
                    Button {
                        showEditFolder = true
                    } label: {
                        Label("Edit Folder", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showCreateNote) {
            NoteEditorView(noteId: nil, folderId: folderId)
        }
        .sheet(isPresented: $showEditFolder) {
            if let folder = viewModel.folder {
                EditFolderSheet(folder: folder) { deleted in
                    if deleted { dismiss() }
                }
            }
        }
    }

    private func softDelete(_ noteId: Int64) {
        try? AppDatabase.shared.writer.write { db in
            let repo = GRDBNoteRepository()
            try repo.softDelete(id: noteId, db: db)
        }
    }

    private func togglePin(_ note: Note) {
        try? AppDatabase.shared.writer.write { db in
            var updated = note
            updated.isPinned.toggle()
            updated.modifiedAt = Date()
            try updated.update(db)
        }
    }
}
