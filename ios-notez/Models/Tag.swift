import Foundation
import GRDB

struct Tag: Codable, Identifiable {
    var id: Int64?
    var name: String
    var color: String?
    var createdAt: Date

    init(
        id: Int64? = nil,
        name: String = "",
        color: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}

// MARK: - Database

extension Tag: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "tag"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let color = Column(CodingKeys.color)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Associations

extension Tag {
    static let noteTags = hasMany(NoteTag.self)
    static let notes = hasMany(Note.self, through: noteTags, using: NoteTag.note)

    var notes: QueryInterfaceRequest<Note> {
        request(for: Tag.notes).filter(Note.Columns.deletedAt == nil)
    }
}

// MARK: - Hashable

extension Tag: Hashable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
