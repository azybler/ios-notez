import Foundation
import GRDB

struct GRDBFolderRepository: FolderRepository {

    // MARK: - Fetch

    func fetchAll(db: Database) throws -> [Folder] {
        try Folder
            .order(Folder.Columns.name.collating(.nocase))
            .fetchAll(db)
    }

    func fetch(id: Int64, db: Database) throws -> Folder? {
        try Folder.fetchOne(db, id: id)
    }

    func fetchTopLevel(db: Database) throws -> [Folder] {
        try Folder
            .filter(Folder.Columns.parentFolderId == nil)
            .order(Folder.Columns.name.collating(.nocase))
            .fetchAll(db)
    }

    func fetchChildren(parentId: Int64, db: Database) throws -> [Folder] {
        try Folder
            .filter(Folder.Columns.parentFolderId == parentId)
            .order(Folder.Columns.name.collating(.nocase))
            .fetchAll(db)
    }

    func fetchAllWithCounts(db: Database) throws -> [FolderWithCount] {
        let topLevel = try fetchTopLevel(db: db)
        let noteRepo = GRDBNoteRepository()

        return try topLevel.map { folder in
            let children = try fetchChildren(parentId: folder.id!, db: db)
            let childCounts = try children.map { child -> FolderWithCount in
                let count = try noteRepo.countByFolder(folderId: child.id!, db: db)
                return FolderWithCount(folder: child, noteCount: count, children: [])
            }
            let directCount = try noteRepo.countByFolder(folderId: folder.id!, db: db)
            let totalCount = directCount + childCounts.reduce(0) { $0 + $1.noteCount }
            return FolderWithCount(folder: folder, noteCount: totalCount, children: childCounts)
        }
    }

    // MARK: - CRUD

    func save(_ folder: inout Folder, db: Database) throws {
        folder.modifiedAt = Date()
        if folder.id == nil {
            folder.createdAt = Date()
        }
        try folder.save(db)
    }

    func delete(id: Int64, db: Database) throws {
        // Move all notes in this folder to unsorted
        try Note
            .filter(Note.Columns.folderId == id)
            .updateAll(db, Note.Columns.folderId.set(to: nil))

        // Promote subfolders to top-level
        try Folder
            .filter(Folder.Columns.parentFolderId == id)
            .updateAll(db, Folder.Columns.parentFolderId.set(to: nil))

        // Delete the folder
        _ = try Folder.deleteOne(db, id: id)
    }
}
