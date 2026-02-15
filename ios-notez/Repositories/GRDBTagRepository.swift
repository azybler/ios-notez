import Foundation
import GRDB

struct GRDBTagRepository: TagRepository {

    // MARK: - Fetch

    func fetchAll(db: Database) throws -> [Tag] {
        try Tag
            .order(Tag.Columns.name.collating(.nocase))
            .fetchAll(db)
    }

    func fetch(id: Int64, db: Database) throws -> Tag? {
        try Tag.fetchOne(db, id: id)
    }

    func fetchAllWithCounts(db: Database) throws -> [TagWithCount] {
        let tags = try fetchAll(db: db)
        let noteRepo = GRDBNoteRepository()
        return try tags.map { tag in
            let count = try noteRepo.countByTag(tagId: tag.id!, db: db)
            return TagWithCount(tag: tag, noteCount: count)
        }
    }

    func fetchNotes(tagId: Int64, db: Database) throws -> [NoteInfo] {
        let notes = try Note.notDeleted()
            .joining(required: Note.noteTags.filter(NoteTag.Columns.tagId == tagId))
            .order(Note.Columns.isPinned.desc, Note.Columns.modifiedAt.desc)
            .fetchAll(db)
        let noteRepo = GRDBNoteRepository()
        return try notes.map { note in
            let tags = try noteRepo.fetchTags(noteId: note.id!, db: db)
            return NoteInfo(note: note, tags: tags)
        }
    }

    // MARK: - CRUD

    func save(_ tag: inout Tag, db: Database) throws {
        if tag.id == nil {
            tag.createdAt = Date()
        }
        try tag.save(db)
    }

    func delete(id: Int64, db: Database) throws {
        // note_tags will cascade delete
        _ = try Tag.deleteOne(db, id: id)
    }

    // MARK: - Merge

    func merge(sourceTagIds: [Int64], targetTagId: Int64, db: Database) throws {
        for sourceTagId in sourceTagIds {
            // Get all note IDs that have the source tag
            let noteIds = try NoteTag
                .filter(NoteTag.Columns.tagId == sourceTagId)
                .select(NoteTag.Columns.noteId, as: Int64.self)
                .fetchAll(db)

            // Get the source tag info for history
            guard let sourceTag = try Tag.fetchOne(db, id: sourceTagId) else { continue }

            // Record merge history
            var history = TagMergeHistory(
                targetTagId: targetTagId,
                sourceTagName: sourceTag.name,
                sourceTagColor: sourceTag.color,
                noteTagSnapshot: TagMergeHistory.encodeSnapshot(noteIds)
            )
            try history.insert(db)

            // Add target tag to notes that don't already have it
            for noteId in noteIds {
                let exists = try NoteTag
                    .filter(NoteTag.Columns.noteId == noteId && NoteTag.Columns.tagId == targetTagId)
                    .fetchCount(db) > 0
                if !exists {
                    try NoteTag(noteId: noteId, tagId: targetTagId).insert(db)
                }
            }

            // Remove source tag from all notes and delete it
            try NoteTag.filter(NoteTag.Columns.tagId == sourceTagId).deleteAll(db)
            _ = try Tag.deleteOne(db, id: sourceTagId)
        }
    }

    func fetchMergeHistory(targetTagId: Int64, db: Database) throws -> [TagMergeHistory] {
        try TagMergeHistory
            .filter(TagMergeHistory.Columns.targetTagId == targetTagId)
            .order(TagMergeHistory.Columns.mergedAt.desc)
            .fetchAll(db)
    }

    func undoMerge(historyId: Int64, db: Database) throws {
        guard let history = try TagMergeHistory.fetchOne(db, id: historyId) else { return }

        // Recreate the source tag
        var sourceTag = Tag(
            name: history.sourceTagName,
            color: history.sourceTagColor
        )
        try sourceTag.insert(db)

        // Re-assign source tag to notes in the snapshot that still exist
        let noteIds = history.noteIds
        for noteId in noteIds {
            // Only re-assign if the note still exists and is not permanently deleted
            if try Note.fetchOne(db, id: noteId) != nil {
                let exists = try NoteTag
                    .filter(NoteTag.Columns.noteId == noteId && NoteTag.Columns.tagId == sourceTag.id!)
                    .fetchCount(db) > 0
                if !exists {
                    try NoteTag(noteId: noteId, tagId: sourceTag.id!).insert(db)
                }
            }
        }

        // Delete the merge history record
        _ = try TagMergeHistory.deleteOne(db, id: historyId)
    }
}
