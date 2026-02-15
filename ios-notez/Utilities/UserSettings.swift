import Foundation
import Observation

@Observable
final class UserSettings {
    static let shared = UserSettings()

    var showSnippets: Bool {
        didSet { UserDefaults.standard.set(showSnippets, forKey: "showSnippets") }
    }

    private init() {
        // Default to true (show snippets)
        if UserDefaults.standard.object(forKey: "showSnippets") == nil {
            UserDefaults.standard.set(true, forKey: "showSnippets")
        }
        self.showSnippets = UserDefaults.standard.bool(forKey: "showSnippets")
    }
}
