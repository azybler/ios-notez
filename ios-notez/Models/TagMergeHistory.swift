import Foundation
import GRDB

struct TagMergeHistory: Codable, Identifiable {
    var id: Int64?
    var targetTagId: Int64
    var sourceTagName: String
    var sourceTagColor: String?
    /// JSON-encoded array of note IDs that originally had the source tag.
    var noteTagSnapshot: String
    var mergedAt: Date

    init(
        id: Int64? = nil,
        targetTagId: Int64,
        sourceTagName: String,
        sourceTagColor: String? = nil,
        noteTagSnapshot: String,
        mergedAt: Date = Date()
    ) {
        self.id = id
        self.targetTagId = targetTagId
        self.sourceTagName = sourceTagName
        self.sourceTagColor = sourceTagColor
        self.noteTagSnapshot = noteTagSnapshot
        self.mergedAt = mergedAt
    }
}

// MARK: - Database

extension TagMergeHistory: FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "tagMergeHistory"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let targetTagId = Column(CodingKeys.targetTagId)
        static let sourceTagName = Column(CodingKeys.sourceTagName)
        static let sourceTagColor = Column(CodingKeys.sourceTagColor)
        static let noteTagSnapshot = Column(CodingKeys.noteTagSnapshot)
        static let mergedAt = Column(CodingKeys.mergedAt)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - Snapshot Helpers

extension TagMergeHistory {
    /// Decode the snapshot into an array of note IDs.
    var noteIds: [Int64] {
        guard let data = noteTagSnapshot.data(using: .utf8),
              let ids = try? JSONDecoder().decode([Int64].self, from: data) else {
            return []
        }
        return ids
    }

    /// Create a snapshot string from an array of note IDs.
    static func encodeSnapshot(_ noteIds: [Int64]) -> String {
        guard let data = try? JSONEncoder().encode(noteIds) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

// MARK: - Associations

extension TagMergeHistory {
    static let targetTag = belongsTo(Tag.self, using: ForeignKey([Columns.targetTagId]))
}
