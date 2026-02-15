import SwiftUI
import Observation
import GRDB

@Observable
@MainActor
final class TagDetailViewModel {
    var notes: [NoteInfo] = []
    var tag: Tag?

    private var cancellable: AnyDatabaseCancellable?
    private let tagId: Int64
    private let database: AppDatabase

    init(tagId: Int64, database: AppDatabase = .shared) {
        self.tagId = tagId
        self.database = database
        startObservation()
    }

    private func startObservation() {
        let tagId = self.tagId
        let observation = ValueObservation.tracking { db -> (Tag?, [NoteInfo]) in
            let tagRepo = GRDBTagRepository()
            let tag = try tagRepo.fetch(id: tagId, db: db)
            let notes = try tagRepo.fetchNotes(tagId: tagId, db: db)
            return (tag, notes)
        }

        cancellable = observation.start(in: database.writer) { _ in
        } onChange: { [weak self] (tag, notes) in
            self?.tag = tag
            self?.notes = notes
        }
    }
}

struct TagDetailView: View {
    let tagId: Int64
    let tagName: String
    @State private var viewModel: TagDetailViewModel
    @State private var showEditTag = false
    @Environment(\.dismiss) private var dismiss

    init(tagId: Int64, tagName: String) {
        self.tagId = tagId
        self.tagName = tagName
        self._viewModel = State(initialValue: TagDetailViewModel(tagId: tagId))
    }

    var body: some View {
        List {
            if viewModel.notes.isEmpty {
                EmptyStateView(
                    icon: "tag",
                    title: "No notes",
                    message: "No notes have this tag."
                )
            } else {
                ForEach(viewModel.notes, id: \.note.id) { noteInfo in
                    NavigationLink {
                        NoteEditorView(noteId: noteInfo.note.id, folderId: noteInfo.note.folderId)
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
        .navigationTitle(tagName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditTag = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditTag) {
            if let tag = viewModel.tag {
                EditTagSheet(tag: tag) { deleted in
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
