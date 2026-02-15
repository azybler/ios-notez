import Foundation
import GRDB

/// The shared database for the app.
struct AppDatabase {
    /// The shared singleton instance.
    static let shared = makeShared()

    /// The database writer (for reads and writes).
    let writer: any DatabaseWriter

    /// A database reader (for reads only).
    var reader: any DatabaseReader { writer }

    /// Creates the database with the given writer and runs migrations.
    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try migrator.migrate(writer)
    }
}

// MARK: - Database Setup

extension AppDatabase {
    private static func makeShared() -> AppDatabase {
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let databaseURL = directoryURL.appendingPathComponent("notez.sqlite")
            let dbQueue = try DatabaseQueue(path: databaseURL.path)
            return try AppDatabase(dbQueue)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    /// An in-memory database for previews and testing.
    static func empty() throws -> AppDatabase {
        let dbQueue = try DatabaseQueue(configuration: .init())
        return try AppDatabase(dbQueue)
    }
}

// MARK: - Migrations

extension AppDatabase {
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1-create-folders") { db in
            try db.create(table: "folder") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("parentFolderId", .integer)
                    .references("folder", onDelete: .setNull)
                t.column("color", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("modifiedAt", .datetime).notNull()
            }
            try db.create(
                index: "folder_on_parentFolderId",
                on: "folder",
                columns: ["parentFolderId"]
            )
        }

        migrator.registerMigration("v1-create-notes") { db in
            try db.create(table: "note") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull().defaults(to: "")
                t.column("body", .text).notNull().defaults(to: "")
                t.column("folderId", .integer)
                    .references("folder", onDelete: .setNull)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
                t.column("createdAt", .datetime).notNull()
                t.column("modifiedAt", .datetime).notNull()
                t.column("deletedAt", .datetime)
            }
            try db.create(index: "note_on_folderId", on: "note", columns: ["folderId"])
            try db.create(index: "note_on_isPinned", on: "note", columns: ["isPinned"])
            try db.create(index: "note_on_deletedAt", on: "note", columns: ["deletedAt"])
            try db.create(index: "note_on_modifiedAt", on: "note", columns: ["modifiedAt"])
        }

        migrator.registerMigration("v1-create-tags") { db in
            try db.create(table: "tag") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique().collate(.nocase)
                t.column("color", .text)
                t.column("createdAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v1-create-note-tags") { db in
            try db.create(table: "noteTag") { t in
                t.column("noteId", .integer)
                    .notNull()
                    .references("note", onDelete: .cascade)
                t.column("tagId", .integer)
                    .notNull()
                    .references("tag", onDelete: .cascade)
                t.primaryKey(["noteId", "tagId"])
            }
            try db.create(index: "noteTag_on_tagId", on: "noteTag", columns: ["tagId"])
        }

        migrator.registerMigration("v1-create-tag-merge-history") { db in
            try db.create(table: "tagMergeHistory") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("targetTagId", .integer)
                    .notNull()
                    .references("tag", onDelete: .cascade)
                t.column("sourceTagName", .text).notNull()
                t.column("sourceTagColor", .text)
                t.column("noteTagSnapshot", .text).notNull()
                t.column("mergedAt", .datetime).notNull()
            }
            try db.create(
                index: "tagMergeHistory_on_targetTagId",
                on: "tagMergeHistory",
                columns: ["targetTagId"]
            )
        }

        return migrator
    }
}

// MARK: - Seed Data (Debug)

#if DEBUG
extension AppDatabase {
    /// Creates a database pre-populated with sample data for previews.
    static func preview() throws -> AppDatabase {
        let db = try empty()
        try db.writer.write { db in
            let now = Date()

            // Create folders
            var workFolder = Folder(name: "Work", color: "#4A90D9", createdAt: now, modifiedAt: now)
            try workFolder.insert(db)

            var personalFolder = Folder(name: "Personal", color: "#50C878", createdAt: now, modifiedAt: now)
            try personalFolder.insert(db)

            var projectsSubfolder = Folder(
                name: "Projects",
                parentFolderId: workFolder.id,
                color: "#7B68EE",
                createdAt: now,
                modifiedAt: now
            )
            try projectsSubfolder.insert(db)

            // Create tags
            var urgentTag = Tag(name: "urgent", color: "#FF6B6B", createdAt: now)
            try urgentTag.insert(db)

            var ideaTag = Tag(name: "idea", color: "#FFD93D", createdAt: now)
            try ideaTag.insert(db)

            var meetingTag = Tag(name: "meeting", color: "#6BCB77", createdAt: now)
            try meetingTag.insert(db)

            // Create notes
            var note1 = Note(
                title: "Project Roadmap",
                body: "## Q1 Goals\n\n- **Launch MVP**\n- User testing\n- Iterate on feedback",
                folderId: projectsSubfolder.id,
                isPinned: true,
                createdAt: now,
                modifiedAt: now
            )
            try note1.insert(db)

            var note2 = Note(
                title: "Meeting Notes",
                body: "Discussed timeline and deliverables.\n\n### Action Items\n\n- Follow up with design team\n- Review budget",
                folderId: workFolder.id,
                createdAt: now.addingTimeInterval(-3600),
                modifiedAt: now.addingTimeInterval(-3600)
            )
            try note2.insert(db)

            var note3 = Note(
                title: "Grocery List",
                body: "- Milk\n- Eggs\n- Bread\n- *Avocados*",
                folderId: personalFolder.id,
                createdAt: now.addingTimeInterval(-7200),
                modifiedAt: now.addingTimeInterval(-7200)
            )
            try note3.insert(db)

            var note4 = Note(
                title: "App Ideas",
                body: "An app that helps you **organize notes** with powerful search and tagging.",
                isPinned: true,
                createdAt: now.addingTimeInterval(-10800),
                modifiedAt: now.addingTimeInterval(-10800)
            )
            try note4.insert(db)

            var note5 = Note(
                title: "Random Thought",
                body: "Sometimes the simplest solution is the best one.",
                createdAt: now.addingTimeInterval(-14400),
                modifiedAt: now.addingTimeInterval(-14400)
            )
            try note5.insert(db)

            // Assign tags
            try NoteTag(noteId: note1.id!, tagId: urgentTag.id!).insert(db)
            try NoteTag(noteId: note1.id!, tagId: meetingTag.id!).insert(db)
            try NoteTag(noteId: note2.id!, tagId: meetingTag.id!).insert(db)
            try NoteTag(noteId: note4.id!, tagId: ideaTag.id!).insert(db)
        }
        return db
    }
}
#endif
