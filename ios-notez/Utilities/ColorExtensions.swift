import SwiftUI

extension Color {
    /// Create a Color from a hex string like "#FF6B6B".
    init?(hex: String?) {
        guard let hex = hex else { return nil }
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

/// Preset colors for folders and tags.
enum PresetColors {
    static let all: [(name: String, hex: String)] = [
        ("Red", "#FF6B6B"),
        ("Orange", "#FFA07A"),
        ("Yellow", "#FFD93D"),
        ("Green", "#6BCB77"),
        ("Mint", "#50C878"),
        ("Teal", "#4ECDC4"),
        ("Blue", "#4A90D9"),
        ("Indigo", "#5C6BC0"),
        ("Purple", "#7B68EE"),
        ("Pink", "#FF69B4"),
        ("Brown", "#A0522D"),
        ("Gray", "#9E9E9E"),
    ]
}
