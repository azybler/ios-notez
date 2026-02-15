import SwiftUI
import GRDB

@Observable
@MainActor
final class PinnedNotesViewModel {
    var notes: [NoteInfo] = []
    private var cancellable: AnyDatabaseCancellable?

    init(database: AppDatabase = .shared) {
        let observation = ValueObservation.tracking { db in
            try GRDBNoteRepository().fetchPinned(db: db)
        }
        cancellable = observation.start(in: database.writer) { _ in
        } onChange: { [weak self] notes in
            self?.notes = notes
        }
    }
}

struct PinnedNotesView: View {
    @State private var viewModel = PinnedNotesViewModel()

    var body: some View {
        List {
            if viewModel.notes.isEmpty {
                EmptyStateView(
                    icon: "pin",
                    title: "No pinned notes",
                    message: "Pin important notes to find them quickly."
                )
            } else {
                ForEach(viewModel.notes, id: \.note.id) { noteInfo in
                    NavigationLink {
                        NoteEditorView(noteId: noteInfo.note.id, folderId: noteInfo.note.folderId)
                    } label: {
                        NoteRowView(noteInfo: noteInfo, showSnippets: UserSettings.shared.showSnippets)
                    }
                }
            }
        }
        .navigationTitle("All Pinned Notes")
    }
}
