import Foundation

enum SnippetGenerator {
    /// Generate a plain-text snippet from Markdown source.
    /// Strips Markdown syntax, takes first 120 characters, replaces newlines with spaces.
    static func generate(from markdown: String, maxLength: Int = 120) -> String {
        var text = markdown

        // Remove headings (# ## ### etc.)
        text = text.replacingOccurrences(
            of: #"^#{1,6}\s+"#, with: "", options: .regularExpression
        )
        // Remove bold/italic markers
        text = text.replacingOccurrences(of: #"\*{1,3}([^*]+)\*{1,3}"#, with: "$1", options: .regularExpression)
        text = text.replacingOccurrences(of: #"_{1,3}([^_]+)_{1,3}"#, with: "$1", options: .regularExpression)
        // Remove inline code
        text = text.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        // Remove links [text](url) → text
        text = text.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        // Remove images ![alt](url)
        text = text.replacingOccurrences(of: #"!\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        // Remove list markers (- * + and numbered)
        text = text.replacingOccurrences(of: #"(?m)^[\s]*[-*+]\s+"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: #"(?m)^[\s]*\d+\.\s+"#, with: "", options: .regularExpression)
        // Remove strikethrough
        text = text.replacingOccurrences(of: #"~~([^~]+)~~"#, with: "$1", options: .regularExpression)
        // Replace newlines with spaces
        text = text.replacingOccurrences(of: #"\n+"#, with: " ", options: .regularExpression)
        // Collapse multiple spaces
        text = text.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        // Trim
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength)
            text = String(text[..<index]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.hasSuffix("...") {
                text += "..."
            }
        }

        return text
    }
}
