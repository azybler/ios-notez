import Foundation
import GRDB

/// Converts a SearchExpression AST into SQL conditions for GRDB queries.
struct SearchQueryBuilder {
    /// Build a SQL expression from a SearchExpression.
    /// Returns the SQL string and its arguments.
    func buildSQL(from expression: SearchExpression) -> (sql: String, arguments: StatementArguments) {
        var args: [DatabaseValueConvertible?] = []
        let sql = buildCondition(expression, args: &args)
        return (sql, StatementArguments(args.map { $0 ?? DatabaseValue.null }))
    }

    /// Execute a search and return matching notes.
    func execute(expression: SearchExpression?, in db: Database) throws -> [NoteInfo] {
        guard let expression else {
            return try GRDBNoteRepository().fetchAll(db: db)
        }

        let (conditionSQL, arguments) = buildSQL(from: expression)

        let sql = """
            SELECT DISTINCT note.*
            FROM note
            LEFT JOIN noteTag ON noteTag.noteId = note.id
            LEFT JOIN tag ON tag.id = noteTag.tagId
            LEFT JOIN folder ON folder.id = note.folderId
            WHERE note.deletedAt IS NULL
            AND (\(conditionSQL))
            ORDER BY note.isPinned DESC, note.modifiedAt DESC
            """

        let notes = try Note.fetchAll(db, sql: sql, arguments: arguments)
        let noteRepo = GRDBNoteRepository()
        return try notes.map { note in
            let tags = try noteRepo.fetchTags(noteId: note.id!, db: db)
            return NoteInfo(note: note, tags: tags)
        }
    }

    private func buildCondition(_ expr: SearchExpression, args: inout [DatabaseValueConvertible?]) -> String {
        switch expr {
        case .tag(let name):
            args.append(name)
            return "tag.name = ? COLLATE NOCASE"

        case .folder(let name):
            args.append(name)
            return "folder.name = ? COLLATE NOCASE"

        case .text(let term):
            let pattern = "%\(term)%"
            args.append(pattern)
            args.append(pattern)
            return "(note.title LIKE ? COLLATE NOCASE OR note.body LIKE ? COLLATE NOCASE)"

        case .pinned(let value):
            args.append(value)
            return "note.isPinned = ?"

        case .and(let left, let right):
            let l = buildCondition(left, args: &args)
            let r = buildCondition(right, args: &args)
            return "(\(l) AND \(r))"

        case .or(let left, let right):
            let l = buildCondition(left, args: &args)
            let r = buildCondition(right, args: &args)
            return "(\(l) OR \(r))"

        case .not(let inner):
            let condition = buildCondition(inner, args: &args)
            return "NOT (\(condition))"
        }
    }
}
