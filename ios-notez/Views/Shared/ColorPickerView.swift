import SwiftUI

struct ColorPickerGridView: View {
    @Binding var selectedColor: String?
    @State private var showCustomPicker = false
    @State private var customColor = Color.accentColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                // No color option
                Button {
                    selectedColor = nil
                } label: {
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == nil {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                }

                // Preset colors
                ForEach(PresetColors.all, id: \.hex) { preset in
                    Button {
                        selectedColor = preset.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex) ?? .gray)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if selectedColor == preset.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
