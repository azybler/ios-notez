import Foundation
import Observation
import GRDB

enum SearchMode {
    case visual
    case text
}

/// Represents a visual filter chip.
struct FilterChip: Identifiable {
    let id = UUID()
    var type: FilterType
    var value: String
    var isNegated: Bool = false

    enum FilterType {
        case tag
        case folder
        case pinned
    }
}

@Observable
@MainActor
final class SearchViewModel {
    var mode: SearchMode = .visual
    var textQuery: String = ""
    var results: [NoteInfo] = []
    var parseError: String? = nil
    var chips: [FilterChip] = []
    var chipLogic: ChipLogic = .and

    enum ChipLogic { case and, or }

    // Available items for visual picker
    var allTags: [Tag] = []
    var allFolders: [Folder] = []

    private let database: AppDatabase

    init(database: AppDatabase = .shared) {
        self.database = database
        loadPickerData()
    }

    func search() {
        let expression: SearchExpression?

        switch mode {
        case .text:
            guard !textQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
                results = []
                parseError = nil
                return
            }
            var parser = SearchQueryParser()
            expression = parser.parse(textQuery)
            parseError = expression == nil ? "Invalid search syntax" : nil

        case .visual:
            expression = buildExpressionFromChips()
        }

        do {
            try database.reader.read { db in
                let builder = SearchQueryBuilder()
                results = try builder.execute(expression: expression, in: db)
            }
        } catch {
            results = []
        }
    }

    func switchToTextMode() {
        let expression = buildExpressionFromChips()
        if let expression {
            textQuery = SearchQuerySerializer().serialize(expression)
        }
        mode = .text
    }

    func switchToVisualMode() {
        // Try to parse text and build chips
        var parser = SearchQueryParser()
        if let _ = parser.parse(textQuery) {
            // For simplicity, clear chips and let user rebuild
            // Complex text queries may not map to visual mode
        }
        mode = .visual
    }

    func addTagChip(_ tag: Tag) {
        chips.append(FilterChip(type: .tag, value: tag.name))
        search()
    }

    func addFolderChip(_ folder: Folder) {
        chips.append(FilterChip(type: .folder, value: folder.name))
        search()
    }

    func addExcludeFolderChip(_ folder: Folder) {
        chips.append(FilterChip(type: .folder, value: folder.name, isNegated: true))
        search()
    }

    func removeChip(_ chip: FilterChip) {
        chips.removeAll { $0.id == chip.id }
        search()
    }

    func clearAll() {
        chips = []
        textQuery = ""
        results = []
        parseError = nil
    }

    private func buildExpressionFromChips() -> SearchExpression? {
        guard !chips.isEmpty else { return nil }

        let expressions: [SearchExpression] = chips.map { chip in
            let base: SearchExpression
            switch chip.type {
            case .tag: base = .tag(chip.value)
            case .folder: base = .folder(chip.value)
            case .pinned: base = .pinned(chip.value == "true")
            }
            return chip.isNegated ? .not(base) : base
        }

        guard var result = expressions.first else { return nil }
        for expr in expressions.dropFirst() {
            switch chipLogic {
            case .and: result = .and(result, expr)
            case .or: result = .or(result, expr)
            }
        }
        return result
    }

    private func loadPickerData() {
        do {
            try database.reader.read { db in
                allTags = try Tag.order(Tag.Columns.name.collating(.nocase)).fetchAll(db)
                allFolders = try Folder.order(Folder.Columns.name.collating(.nocase)).fetchAll(db)
            }
        } catch {}
    }
}
