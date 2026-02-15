import Foundation

struct SearchQueryTokenizer {
    func tokenize(_ input: String) -> [SearchQueryToken] {
        var tokens: [SearchQueryToken] = []
        let scanner = Scanner(string: input)
        scanner.charactersToBeSkipped = nil

        while !scanner.isAtEnd {
            skipWhitespace(scanner)
            guard !scanner.isAtEnd else { break }

            if scanner.scanString("(") != nil {
                tokens.append(.openParen)
            } else if scanner.scanString(")") != nil {
                tokens.append(.closeParen)
            } else if scanKeyword("AND", scanner: scanner) {
                tokens.append(.and)
            } else if scanKeyword("OR", scanner: scanner) {
                tokens.append(.or)
            } else if scanKeyword("NOT", scanner: scanner) {
                tokens.append(.not)
            } else if let token = scanPrefix("tag:", scanner: scanner) {
                tokens.append(.tag(token))
            } else if let token = scanPrefix("folder:", scanner: scanner) {
                tokens.append(.folder(token))
            } else if scanKeyword("pinned:true", scanner: scanner) {
                tokens.append(.pinned(true))
            } else if scanKeyword("pinned:false", scanner: scanner) {
                tokens.append(.pinned(false))
            } else if let word = scanWord(scanner) {
                tokens.append(.text(word))
            } else {
                // Skip unknown character
                scanner.currentIndex = scanner.string.index(after: scanner.currentIndex)
            }
        }

        return tokens
    }

    private func skipWhitespace(_ scanner: Scanner) {
        _ = scanner.scanCharacters(from: .whitespaces)
    }

    private func scanKeyword(_ keyword: String, scanner: Scanner) -> Bool {
        let saved = scanner.currentIndex
        let remaining = scanner.string[scanner.currentIndex...]

        guard remaining.uppercased().hasPrefix(keyword.uppercased()) else { return false }

        let endIndex = scanner.string.index(scanner.currentIndex, offsetBy: keyword.count)

        // Make sure keyword is not part of a longer word
        if endIndex < scanner.string.endIndex {
            let nextChar = scanner.string[endIndex]
            if nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
                scanner.currentIndex = saved
                return false
            }
        }

        scanner.currentIndex = endIndex
        return true
    }

    private func scanPrefix(_ prefix: String, scanner: Scanner) -> String? {
        let saved = scanner.currentIndex
        let remaining = scanner.string[scanner.currentIndex...]

        guard remaining.lowercased().hasPrefix(prefix.lowercased()) else { return nil }

        scanner.currentIndex = scanner.string.index(scanner.currentIndex, offsetBy: prefix.count)

        if let value = scanQuotedOrWord(scanner) {
            return value
        }

        scanner.currentIndex = saved
        return nil
    }

    private func scanQuotedOrWord(_ scanner: Scanner) -> String? {
        if scanner.scanString("\"") != nil {
            let text = scanner.scanUpToString("\"") ?? ""
            _ = scanner.scanString("\"")
            return text
        }
        return scanWord(scanner)
    }

    private func scanWord(_ scanner: Scanner) -> String? {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return scanner.scanCharacters(from: allowed)
    }
}
