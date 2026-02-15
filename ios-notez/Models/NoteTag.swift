import Foundation
import GRDB

struct NoteTag: Codable {
    var noteId: Int64
    var tagId: Int64
}

// MARK: - Database

extension NoteTag: FetchableRecord, PersistableRecord {
    static let databaseTableName = "noteTag"

    enum Columns {
        static let noteId = Column(CodingKeys.noteId)
        static let tagId = Column(CodingKeys.tagId)
    }
}

// MARK: - Associations

extension NoteTag {
    static let note = belongsTo(Note.self)
    static let tag = belongsTo(Tag.self)
}
