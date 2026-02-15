import Foundation

enum SearchQueryToken: Equatable {
    case tag(String)
    case folder(String)
    case text(String)
    case and
    case or
    case not
    case openParen
    case closeParen
    case pinned(Bool)
}
