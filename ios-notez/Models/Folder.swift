import Foundation
import GRDB

struct Folder: Codable, Identifiable {
    var id: Int64?
    var name: String
    var parentFolderId: Int64?
    var color: String?
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: Int64? = nil,
        name: String = "",
        parentFolderId: Int64? = nil,
        color: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.parentFolderId = parentFolderId
        self.color = color
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Database

extension Folder: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "folder"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let parentFolderId = Column(CodingKeys.parentFolderId)
        static let color = Column(CodingKeys.color)
        static let createdAt = Column(CodingKeys.createdAt)
        static let modifiedAt = Column(CodingKeys.modifiedAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Associations

extension Folder {
    static let notes = hasMany(Note.self)
    static let parentFolderFK = ForeignKey([Columns.parentFolderId])
    static let parentFolder = belongsTo(Folder.self, using: parentFolderFK)
    static let childFolders = hasMany(Folder.self, using: parentFolderFK)

    var notes: QueryInterfaceRequest<Note> {
        request(for: Folder.notes).filter(Note.Columns.deletedAt == nil)
    }

    var childFolders: QueryInterfaceRequest<Folder> {
        request(for: Folder.childFolders)
    }
}

// MARK: - Computed

extension Folder {
    /// Whether this is a top-level folder (no parent).
    var isTopLevel: Bool {
        parentFolderId == nil
    }
}

// MARK: - Hashable

extension Folder: Hashable {
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
