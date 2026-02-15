import Foundation
import GRDB

/// A folder with its note count (including subfolder notes).
struct FolderWithCount: Equatable {
    var folder: Folder
    var noteCount: Int
    var children: [FolderWithCount]
}

protocol FolderRepository: Sendable {
    // MARK: - Fetch
    func fetchAll(db: Database) throws -> [Folder]
    func fetch(id: Int64, db: Database) throws -> Folder?
    func fetchTopLevel(db: Database) throws -> [Folder]
    func fetchChildren(parentId: Int64, db: Database) throws -> [Folder]

    /// Fetch all top-level folders with recursive note counts and children.
    func fetchAllWithCounts(db: Database) throws -> [FolderWithCount]

    // MARK: - CRUD
    func save(_ folder: inout Folder, db: Database) throws
    func delete(id: Int64, db: Database) throws
}
