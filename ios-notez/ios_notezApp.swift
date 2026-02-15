import SwiftUI
import GRDBQuery

@main
struct ios_notezApp: App {
    init() {
        // Auto-purge trashed notes older than 30 days on launch
        try? AppDatabase.shared.writer.write { db in
            try GRDBNoteRepository().purgeOldTrashed(olderThanDays: 30, db: db)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .databaseContext(.readWrite { AppDatabase.shared.writer })
    }
}
