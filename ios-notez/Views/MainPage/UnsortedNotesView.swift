import SwiftUI
import GRDB

@Observable
@MainActor
final class UnsortedNotesViewModel {
    var notes: [NoteInfo] = []
    private var cancellable: AnyDatabaseCancellable?

    init(database: AppDatabase = .shared) {
        let observation = ValueObservation.tracking { db in
            try GRDBNoteRepository().fetchUnsorted(db: db)
        }
        cancellable = observation.start(in: database.writer) { _ in
        } onChange: { [weak self] notes in
            self?.notes = notes
        }
    }
}

struct UnsortedNotesView: View {
    @State private var viewModel = UnsortedNotesViewModel()
    @State private var showCreateNote = false

    var body: some View {
        List {
            if viewModel.notes.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No unsorted notes",
                    message: "Notes not assigned to a folder appear here."
                )
            } else {
                ForEach(viewModel.notes, id: \.note.id) { noteInfo in
                    NavigationLink {
                        NoteEditorView(noteId: noteInfo.note.id, folderId: nil)
                    } label: {
                        NoteRowView(noteInfo: noteInfo, showSnippets: UserSettings.shared.showSnippets)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            try? AppDatabase.shared.writer.write { db in
                                try GRDBNoteRepository().softDelete(id: noteInfo.note.id!, db: db)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            try? AppDatabase.shared.writer.write { db in
                                var updated = noteInfo.note
                                updated.isPinned.toggle()
                                updated.modifiedAt = Date()
                                try updated.update(db)
                            }
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
        .navigationTitle("Unsorted Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateNote = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateNote) {
            NoteEditorView(noteId: nil, folderId: nil)
        }
    }
}
