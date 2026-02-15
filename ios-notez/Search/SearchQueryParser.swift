import Foundation

/// AST node for search expressions.
indirect enum SearchExpression: Equatable {
    case tag(String)
    case folder(String)
    case text(String)
    case pinned(Bool)
    case and(SearchExpression, SearchExpression)
    case or(SearchExpression, SearchExpression)
    case not(SearchExpression)
}

struct SearchQueryParser {
    private var tokens: [SearchQueryToken] = []
    private var position: Int = 0

    /// Parse a query string into a SearchExpression AST.
    mutating func parse(_ input: String) -> SearchExpression? {
        let tokenizer = SearchQueryTokenizer()
        tokens = tokenizer.tokenize(input)
        position = 0

        guard !tokens.isEmpty else { return nil }
        return parseOr()
    }

    // Precedence: OR < AND < NOT < atom
    private mutating func parseOr() -> SearchExpression? {
        guard var left = parseAnd() else { return nil }

        while position < tokens.count, tokens[position] == .or {
            position += 1
            guard let right = parseAnd() else { return left }
            left = .or(left, right)
        }

        return left
    }

    private mutating func parseAnd() -> SearchExpression? {
        guard var left = parseNot() else { return nil }

        while position < tokens.count {
            if tokens[position] == .and {
                position += 1
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else if case .tag = tokens[position],
                      position > 0 {
                // Implicit AND between adjacent terms
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else if case .folder = tokens[position],
                      position > 0 {
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else if case .text = tokens[position],
                      position > 0 {
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else if case .pinned = tokens[position],
                      position > 0 {
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else if tokens[position] == .openParen {
                guard let right = parseNot() else { return left }
                left = .and(left, right)
            } else {
                break
            }
        }

        return left
    }

    private mutating func parseNot() -> SearchExpression? {
        if position < tokens.count, tokens[position] == .not {
            position += 1
            guard let expr = parseAtom() else { return nil }
            return .not(expr)
        }
        return parseAtom()
    }

    private mutating func parseAtom() -> SearchExpression? {
        guard position < tokens.count else { return nil }

        switch tokens[position] {
        case .tag(let name):
            position += 1
            return .tag(name)
        case .folder(let name):
            position += 1
            return .folder(name)
        case .text(let term):
            position += 1
            return .text(term)
        case .pinned(let value):
            position += 1
            return .pinned(value)
        case .openParen:
            position += 1
            let expr = parseOr()
            if position < tokens.count, tokens[position] == .closeParen {
                position += 1
            }
            return expr
        default:
            return nil
        }
    }
}
