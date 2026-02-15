import SwiftUI
import GRDB

@Observable
@MainActor
final class TrashViewModel {
    var notes: [NoteInfo] = []
    private var cancellable: AnyDatabaseCancellable?

    init(database: AppDatabase = .shared) {
        let observation = ValueObservation.tracking { db in
            try GRDBNoteRepository().fetchTrashed(db: db)
        }
        cancellable = observation.start(in: database.writer) { _ in
        } onChange: { [weak self] notes in
            self?.notes = notes
        }
    }
}

struct TrashView: View {
    @State private var viewModel = TrashViewModel()
    @State private var showEmptyTrashAlert = false

    var body: some View {
        List {
            if viewModel.notes.isEmpty {
                EmptyStateView(
                    icon: "trash",
                    title: "Trash is empty",
                    message: "Deleted notes appear here for 30 days before being permanently removed."
                )
            } else {
                ForEach(viewModel.notes, id: \.note.id) { noteInfo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(noteInfo.note.title.isEmpty ? "Untitled" : noteInfo.note.title)
                            .font(.body)
                            .lineLimit(1)

                        if let deletedAt = noteInfo.note.deletedAt {
                            let daysRemaining = max(0, 30 - Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day!)
                            Text("Deleted \(deletedAt, style: .relative) ago \u{2022} \(daysRemaining) days left")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        let snippet = SnippetGenerator.generate(from: noteInfo.note.body)
                        if !snippet.isEmpty {
                            Text(snippet)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            restore(noteInfo.note.id!)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            permanentDelete(noteInfo.note.id!)
                        } label: {
                            Label("Delete Forever", systemImage: "trash.slash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Trash")
        .toolbar {
            if !viewModel.notes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showEmptyTrashAlert = true
                    } label: {
                        Text("Empty Trash")
                    }
                }
            }
        }
        .alert("Empty Trash?", isPresented: $showEmptyTrashAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete All", role: .destructive) {
                emptyTrash()
            }
        } message: {
            Text("This will permanently delete \(viewModel.notes.count) note(s). This cannot be undone.")
        }
    }

    private func restore(_ noteId: Int64) {
        try? AppDatabase.shared.writer.write { db in
            try GRDBNoteRepository().restore(id: noteId, db: db)
        }
    }

    private func permanentDelete(_ noteId: Int64) {
        try? AppDatabase.shared.writer.write { db in
            try GRDBNoteRepository().delete(id: noteId, db: db)
        }
    }

    private func emptyTrash() {
        try? AppDatabase.shared.writer.write { db in
            try Note.deleted().deleteAll(db)
        }
    }
}
