import SwiftUI

struct MergeHistoryView: View {
    let targetTag: Tag
    @State private var history: [TagMergeHistory] = []
    @State private var showUndoAlert = false
    @State private var selectedHistory: TagMergeHistory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if history.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No merge history",
                        message: "Merge other tags into this one to see history here."
                    )
                } else {
                    ForEach(history, id: \.id) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entry.sourceTagName)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(targetTag.name)
                                    .fontWeight(.medium)
                            }

                            Text("Merged \(entry.mergedAt, style: .relative) ago \u{2022} \(entry.noteIds.count) notes affected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedHistory = entry
                                showUndoAlert = true
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.orange)
                        }
                    }

                    Section {
                        Text("Only the most recent merge can be undone (newest first).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Merge History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Undo Merge?", isPresented: $showUndoAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Undo") {
                    if let entry = selectedHistory {
                        undoMerge(entry)
                    }
                }
            } message: {
                if let entry = selectedHistory {
                    Text("This will recreate the \"\(entry.sourceTagName)\" tag and restore it to applicable notes.")
                }
            }
            .onAppear { loadHistory() }
        }
    }

    private func loadHistory() {
        do {
            try AppDatabase.shared.reader.read { db in
                history = try GRDBTagRepository().fetchMergeHistory(targetTagId: targetTag.id!, db: db)
            }
        } catch {}
    }

    private func undoMerge(_ entry: TagMergeHistory) {
        do {
            try AppDatabase.shared.writer.write { db in
                try GRDBTagRepository().undoMerge(historyId: entry.id!, db: db)
            }
            loadHistory()
        } catch {}
    }
}
