import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Mode toggle
            Picker("Search Mode", selection: $viewModel.mode) {
                Text("Visual").tag(SearchMode.visual)
                Text("Text").tag(SearchMode.text)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .onChange(of: viewModel.mode) { oldMode, newMode in
                if oldMode == .visual && newMode == .text {
                    viewModel.switchToTextMode()
                }
            }

            if viewModel.mode == .text {
                TextSearchInputView(viewModel: viewModel)
            } else {
                VisualFilterView(viewModel: viewModel)
            }

            Divider()

            // Results
            if viewModel.results.isEmpty && hasActiveSearch {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No results",
                    message: "No notes match your search."
                )
            } else {
                List(viewModel.results, id: \.note.id) { noteInfo in
                    NavigationLink {
                        NoteEditorView(noteId: noteInfo.note.id, folderId: noteInfo.note.folderId)
                    } label: {
                        NoteRowView(noteInfo: noteInfo, showSnippets: UserSettings.shared.showSnippets)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hasActiveSearch: Bool {
        switch viewModel.mode {
        case .text: return !viewModel.textQuery.trimmingCharacters(in: .whitespaces).isEmpty
        case .visual: return !viewModel.chips.isEmpty
        }
    }
}

// MARK: - Text Search Input

struct TextSearchInputView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("e.g. tag:work AND NOT folder:archive", text: $viewModel.textQuery)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit { viewModel.search() }
                .padding(.horizontal)
                .padding(.top, 8)

            if let error = viewModel.parseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack {
                Text("Syntax: tag:name, folder:name, AND, OR, NOT, ()")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Search") { viewModel.search() }
                    .font(.caption)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Visual Filter

struct VisualFilterView: View {
    @Bindable var viewModel: SearchViewModel
    @State private var showTagPicker = false
    @State private var showFolderPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Active chips
            if !viewModel.chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.chips) { chip in
                            HStack(spacing: 4) {
                                if chip.isNegated {
                                    Text("NOT")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                Image(systemName: chip.type == .tag ? "tag" : "folder")
                                    .font(.caption2)
                                Text(chip.value)
                                    .font(.caption)
                                Button {
                                    viewModel.removeChip(chip)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(chip.isNegated ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        // Logic toggle
                        Button {
                            viewModel.chipLogic = viewModel.chipLogic == .and ? .or : .and
                            viewModel.search()
                        } label: {
                            Text(viewModel.chipLogic == .and ? "AND" : "OR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.fill.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Add filter buttons
            HStack(spacing: 8) {
                Menu {
                    ForEach(viewModel.allTags) { tag in
                        Button(tag.name) { viewModel.addTagChip(tag) }
                    }
                } label: {
                    Label("Tag", systemImage: "tag")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach(viewModel.allFolders) { folder in
                        Button("Include: \(folder.name)") { viewModel.addFolderChip(folder) }
                        Button("Exclude: \(folder.name)") { viewModel.addExcludeFolderChip(folder) }
                    }
                } label: {
                    Label("Folder", systemImage: "folder")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                if !viewModel.chips.isEmpty {
                    Button {
                        viewModel.clearAll()
                    } label: {
                        Text("Clear")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}
