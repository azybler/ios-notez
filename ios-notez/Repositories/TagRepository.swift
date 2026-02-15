import Foundation
import GRDB

/// A tag with its note count.
struct TagWithCount: Equatable {
    var tag: Tag
    var noteCount: Int
}

protocol TagRepository: Sendable {
    // MARK: - Fetch
    func fetchAll(db: Database) throws -> [Tag]
    func fetch(id: Int64, db: Database) throws -> Tag?
    func fetchAllWithCounts(db: Database) throws -> [TagWithCount]
    func fetchNotes(tagId: Int64, db: Database) throws -> [NoteInfo]

    // MARK: - CRUD
    func save(_ tag: inout Tag, db: Database) throws
    func delete(id: Int64, db: Database) throws

    // MARK: - Merge
    func merge(sourceTagIds: [Int64], targetTagId: Int64, db: Database) throws
    func fetchMergeHistory(targetTagId: Int64, db: Database) throws -> [TagMergeHistory]
    func undoMerge(historyId: Int64, db: Database) throws
}
