import Foundation

/// Converts a SearchExpression back to text query syntax.
struct SearchQuerySerializer {
    func serialize(_ expression: SearchExpression) -> String {
        switch expression {
        case .tag(let name):
            return needsQuotes(name) ? "tag:\"\(name)\"" : "tag:\(name)"
        case .folder(let name):
            return needsQuotes(name) ? "folder:\"\(name)\"" : "folder:\(name)"
        case .text(let term):
            return needsQuotes(term) ? "\"\(term)\"" : term
        case .pinned(let value):
            return "pinned:\(value)"
        case .and(let left, let right):
            return "\(serialize(left)) AND \(serialize(right))"
        case .or(let left, let right):
            return "(\(serialize(left)) OR \(serialize(right)))"
        case .not(let inner):
            return "NOT \(serialize(inner))"
        }
    }

    private func needsQuotes(_ name: String) -> Bool {
        name.contains(" ") || name.contains("-") || name.contains("(") || name.contains(")")
    }
}
