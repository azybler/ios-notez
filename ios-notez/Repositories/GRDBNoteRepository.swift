import Foundation
import GRDB

struct GRDBNoteRepository: NoteRepository {

    // MARK: - Fetch

    func fetchAll(db: Database) throws -> [NoteInfo] {
        let notes = try Note.defaultOrder().fetchAll(db)
        return try notes.map { try noteInfo(for: $0, db: db) }
    }

    func fetch(id: Int64, db: Database) throws -> NoteInfo? {
        guard let note = try Note.fetchOne(db, id: id) else { return nil }
        return try noteInfo(for: note, db: db)
    }

    func fetchByFolder(folderId: Int64, db: Database) throws -> [NoteInfo] {
        let notes = try Note.notDeleted()
            .filter(Note.Columns.folderId == folderId)
            .order(Note.Columns.isPinned.desc, Note.Columns.modifiedAt.desc)
            .fetchAll(db)
        return try notes.map { try noteInfo(for: $0, db: db) }
    }

    func fetchUnsorted(db: Database) throws -> [NoteInfo] {
        let notes = try Note.notDeleted()
            .filter(Note.Columns.folderId == nil)
            .order(Note.Columns.isPinned.desc, Note.Columns.modifiedAt.desc)
            .fetchAll(db)
        return try notes.map { try noteInfo(for: $0, db: db) }
    }

    func fetchPinned(db: Database) throws -> [NoteInfo] {
        let notes = try Note.notDeleted()
            .filter(Note.Columns.isPinned == true)
            .order(Note.Columns.modifiedAt.desc)
            .fetchAll(db)
        return try notes.map { try noteInfo(for: $0, db: db) }
    }

    func fetchTrashed(db: Database) throws -> [NoteInfo] {
        let notes = try Note.deleted()
            .order(Note.Columns.deletedAt.desc)
            .fetchAll(db)
        return try notes.map { try noteInfo(for: $0, db: db) }
    }

    // MARK: - Counts

    func countAll(db: Database) throws -> Int {
        try Note.notDeleted().fetchCount(db)
    }

    func countPinned(db: Database) throws -> Int {
        try Note.notDeleted()
            .filter(Note.Columns.isPinned == true)
            .fetchCount(db)
    }

    func countUnsorted(db: Database) throws -> Int {
        try Note.notDeleted()
            .filter(Note.Columns.folderId == nil)
            .fetchCount(db)
    }

    func countByFolder(folderId: Int64, db: Database) throws -> Int {
        try Note.notDeleted()
            .filter(Note.Columns.folderId == folderId)
            .fetchCount(db)
    }

    func countByTag(tagId: Int64, db: Database) throws -> Int {
        try Note.notDeleted()
            .joining(required: Note.noteTags.filter(NoteTag.Columns.tagId == tagId))
            .fetchCount(db)
    }

    func countTrashed(db: Database) throws -> Int {
        try Note.deleted().fetchCount(db)
    }

    // MARK: - CRUD

    func save(_ note: inout Note, db: Database) throws {
        note.modifiedAt = Date()
        if note.id == nil {
            note.createdAt = Date()
        }
        try note.save(db)
    }

    func delete(id: Int64, db: Database) throws {
        _ = try Note.deleteOne(db, id: id)
    }

    func softDelete(id: Int64, db: Database) throws {
        if var note = try Note.fetchOne(db, id: id) {
            note.deletedAt = Date()
            try note.update(db)
        }
    }

    func restore(id: Int64, db: Database) throws {
        if var note = try Note.fetchOne(db, id: id) {
            // If the original folder no longer exists, set to unsorted
            if let folderId = note.folderId {
                if try Folder.fetchOne(db, id: folderId) == nil {
                    note.folderId = nil
                }
            }
            note.deletedAt = nil
            try note.update(db)
        }
    }

    func purgeOldTrashed(olderThanDays days: Int, db: Database) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        try Note
            .filter(Note.Columns.deletedAt != nil && Note.Columns.deletedAt < cutoff)
            .deleteAll(db)
    }

    // MARK: - Tags

    func fetchTags(noteId: Int64, db: Database) throws -> [Tag] {
        try Tag
            .joining(required: Tag.noteTags.filter(NoteTag.Columns.noteId == noteId))
            .order(Tag.Columns.name.collating(.nocase))
            .fetchAll(db)
    }

    func setTags(noteId: Int64, tagIds: [Int64], db: Database) throws {
        // Remove existing
        try NoteTag
            .filter(NoteTag.Columns.noteId == noteId)
            .deleteAll(db)
        // Add new
        for tagId in tagIds {
            try NoteTag(noteId: noteId, tagId: tagId).insert(db)
        }
    }

    // MARK: - Private

    private func noteInfo(for note: Note, db: Database) throws -> NoteInfo {
        let tags = try fetchTags(noteId: note.id!, db: db)
        return NoteInfo(note: note, tags: tags)
    }
}
