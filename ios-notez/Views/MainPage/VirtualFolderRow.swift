import SwiftUI

struct VirtualFolderRow: View {
    let icon: String
    let title: String
    let count: Int
    let tintColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tintColor)
                .frame(width: 28)

            Text(title)
                .font(.body)

            Spacer()

            Text("\(count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
