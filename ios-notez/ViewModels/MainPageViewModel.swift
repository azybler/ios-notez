import Foundation
import Observation
import GRDB

@Observable
@MainActor
final class MainPageViewModel {
    var pinnedCount: Int = 0
    var unsortedCount: Int = 0
    var trashedCount: Int = 0
    var folders: [FolderWithCount] = []
    var tags: [TagWithCount] = []

    private var cancellable: AnyDatabaseCancellable?
    private let database: AppDatabase

    init(database: AppDatabase = .shared) {
        self.database = database
        startObservation()
    }

    private func startObservation() {
        let observation = ValueObservation.tracking { db -> MainPageData in
            let noteRepo = GRDBNoteRepository()
            let folderRepo = GRDBFolderRepository()
            let tagRepo = GRDBTagRepository()

            return MainPageData(
                pinnedCount: try noteRepo.countPinned(db: db),
                unsortedCount: try noteRepo.countUnsorted(db: db),
                trashedCount: try noteRepo.countTrashed(db: db),
                folders: try folderRepo.fetchAllWithCounts(db: db),
                tags: try tagRepo.fetchAllWithCounts(db: db)
            )
        }

        cancellable = observation.start(in: database.writer) { [weak self] error in
            // Observation errors are not expected in normal operation
        } onChange: { [weak self] data in
            self?.pinnedCount = data.pinnedCount
            self?.unsortedCount = data.unsortedCount
            self?.trashedCount = data.trashedCount
            self?.folders = data.folders
            self?.tags = data.tags
        }
    }
}

private struct MainPageData {
    var pinnedCount: Int
    var unsortedCount: Int
    var trashedCount: Int
    var folders: [FolderWithCount]
    var tags: [TagWithCount]
}
