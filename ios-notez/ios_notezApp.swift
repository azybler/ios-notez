import SwiftUI
import GRDBQuery

@main
struct ios_notezApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .databaseContext(.readWrite { AppDatabase.shared.writer })
    }
}
