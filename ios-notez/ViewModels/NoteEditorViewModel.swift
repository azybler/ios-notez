import Foundation
import Observation
import GRDB

@Observable
@MainActor
final class NoteEditorViewModel {
    var title: String = ""
    var body: String = ""
    var isPinned: Bool = false
    var folderId: Int64?
    var selectedTagIds: Set<Int64> = []
    var allFolders: [Folder] = []
    var allTags: [Tag] = []
    var isNew: Bool { noteId == nil }

    private var noteId: Int64?
    private let database: AppDatabase
    private var saveWorkItem: DispatchWorkItem?

    init(noteId: Int64?, folderId: Int64?, database: AppDatabase = .shared) {
        self.noteId = noteId
        self.folderId = folderId
        self.database = database
        loadData()
    }

    private func loadData() {
        do {
            try database.reader.read { [self] db in
                allFolders = try Folder.order(Folder.Columns.name.collating(.nocase)).fetchAll(db)
                allTags = try Tag.order(Tag.Columns.name.collating(.nocase)).fetchAll(db)

                if let id = noteId, let note = try Note.fetchOne(db, id: id) {
                    title = note.title
                    body = note.body
                    isPinned = note.isPinned
                    folderId = note.folderId
                    let tags = try GRDBNoteRepository().fetchTags(noteId: id, db: db)
                    selectedTagIds = Set(tags.compactMap(\.id))
                }
            }
        } catch {}
    }

    func save() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    func saveImmediately() {
        saveWorkItem?.cancel()
        let currentNoteId = noteId
        let currentTitle = title
        let currentBody = body
        let currentFolderId = folderId
        let currentIsPinned = isPinned
        let currentTagIds = Array(selectedTagIds)

        do {
            var savedId: Int64?
            try database.writer.write { db in
                let noteRepo = GRDBNoteRepository()
                var note = Note(
                    id: currentNoteId,
                    title: currentTitle,
                    body: currentBody,
                    folderId: currentFolderId,
                    isPinned: currentIsPinned
                )
                if let id = currentNoteId, let existing = try Note.fetchOne(db, id: id) {
                    note.createdAt = existing.createdAt
                    note.deletedAt = existing.deletedAt
                }
                try noteRepo.save(&note, db: db)
                savedId = note.id
                try noteRepo.setTags(noteId: note.id!, tagIds: currentTagIds, db: db)
            }
            if let savedId {
                noteId = savedId
            }
        } catch {}
    }
}
