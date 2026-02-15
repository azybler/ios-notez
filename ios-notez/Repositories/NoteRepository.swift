import Foundation
import GRDB

/// Information about a note including its associated tags.
struct NoteInfo: Decodable, FetchableRecord, Equatable {
    var note: Note
    var tags: [Tag]
}

protocol NoteRepository: Sendable {
    // MARK: - Fetch
    func fetchAll(db: Database) throws -> [NoteInfo]
    func fetch(id: Int64, db: Database) throws -> NoteInfo?
    func fetchByFolder(folderId: Int64, db: Database) throws -> [NoteInfo]
    func fetchUnsorted(db: Database) throws -> [NoteInfo]
    func fetchPinned(db: Database) throws -> [NoteInfo]
    func fetchTrashed(db: Database) throws -> [NoteInfo]

    // MARK: - Counts
    func countAll(db: Database) throws -> Int
    func countPinned(db: Database) throws -> Int
    func countUnsorted(db: Database) throws -> Int
    func countByFolder(folderId: Int64, db: Database) throws -> Int
    func countByTag(tagId: Int64, db: Database) throws -> Int
    func countTrashed(db: Database) throws -> Int

    // MARK: - CRUD
    func save(_ note: inout Note, db: Database) throws
    func delete(id: Int64, db: Database) throws
    func softDelete(id: Int64, db: Database) throws
    func restore(id: Int64, db: Database) throws
    func purgeOldTrashed(olderThanDays days: Int, db: Database) throws

    // MARK: - Tags
    func fetchTags(noteId: Int64, db: Database) throws -> [Tag]
    func setTags(noteId: Int64, tagIds: [Int64], db: Database) throws
}
