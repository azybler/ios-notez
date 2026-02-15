import Foundation
import GRDB

struct Note: Codable, Identifiable {
    var id: Int64?
    var title: String
    var body: String
    var folderId: Int64?
    var isPinned: Bool
    var createdAt: Date
    var modifiedAt: Date
    var deletedAt: Date?

    init(
        id: Int64? = nil,
        title: String = "",
        body: String = "",
        folderId: Int64? = nil,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.folderId = folderId
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - Database

extension Note: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "note"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let body = Column(CodingKeys.body)
        static let folderId = Column(CodingKeys.folderId)
        static let isPinned = Column(CodingKeys.isPinned)
        static let createdAt = Column(CodingKeys.createdAt)
        static let modifiedAt = Column(CodingKeys.modifiedAt)
        static let deletedAt = Column(CodingKeys.deletedAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Associations

extension Note {
    static let folder = belongsTo(Folder.self)
    static let noteTags = hasMany(NoteTag.self)
    static let tags = hasMany(Tag.self, through: noteTags, using: NoteTag.tag)

    var folder: QueryInterfaceRequest<Folder> {
        request(for: Note.folder)
    }

    var tags: QueryInterfaceRequest<Tag> {
        request(for: Note.tags)
    }
}

// MARK: - Scopes

extension Note {
    /// Active (not deleted) notes.
    static func notDeleted() -> QueryInterfaceRequest<Note> {
        filter(Columns.deletedAt == nil)
    }

    /// Deleted (in trash) notes.
    static func deleted() -> QueryInterfaceRequest<Note> {
        filter(Columns.deletedAt != nil)
    }

    /// Notes in trash older than the given number of days.
    static func trashedOlderThan(days: Int) -> QueryInterfaceRequest<Note> {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return filter(Columns.deletedAt != nil && Columns.deletedAt < cutoff)
    }

    /// Active notes sorted with pinned first, then by modified date descending.
    static func defaultOrder() -> QueryInterfaceRequest<Note> {
        notDeleted().order(Columns.isPinned.desc, Columns.modifiedAt.desc)
    }
}

// MARK: - Hashable

extension Note: Hashable {
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
