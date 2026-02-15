import SwiftUI

struct FolderRow: View {
    let folderWithCount: FolderWithCount
    let isSubfolder: Bool

    init(folderWithCount: FolderWithCount, isSubfolder: Bool = false) {
        self.folderWithCount = folderWithCount
        self.isSubfolder = isSubfolder
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSubfolder ? "folder" : "folder.fill")
                .font(.title3)
                .foregroundStyle(Color(hex: folderWithCount.folder.color) ?? .accentColor)
                .frame(width: 28)

            Text(folderWithCount.folder.name)
                .font(.body)

            Spacer()

            Text("\(folderWithCount.noteCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .padding(.leading, isSubfolder ? 20 : 0)
    }
}
