import SwiftUI

struct MainPageView: View {
    @State private var viewModel = MainPageViewModel()
    @State private var showCreateNote = false
    @State private var showCreateFolder = false
    @State private var showCreateTag = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Virtual folders
                Section {
                    NavigationLink {
                        PinnedNotesView()
                    } label: {
                        VirtualFolderRow(
                            icon: "pin.fill",
                            title: "All Pinned Notes",
                            count: viewModel.pinnedCount,
                            tintColor: .orange
                        )
                    }

                    NavigationLink {
                        UnsortedNotesView()
                    } label: {
                        VirtualFolderRow(
                            icon: "tray.fill",
                            title: "Unsorted Notes",
                            count: viewModel.unsortedCount,
                            tintColor: .gray
                        )
                    }
                }

                // Folders
                if !viewModel.folders.isEmpty {
                    Section("Folders") {
                        ForEach(viewModel.folders, id: \.folder.id) { folderWithCount in
                            NavigationLink {
                                FolderDetailView(folderId: folderWithCount.folder.id!, folderName: folderWithCount.folder.name)
                            } label: {
                                FolderRow(folderWithCount: folderWithCount)
                            }

                            // Show subfolders nested
                            ForEach(folderWithCount.children, id: \.folder.id) { child in
                                NavigationLink {
                                    FolderDetailView(folderId: child.folder.id!, folderName: child.folder.name)
                                } label: {
                                    FolderRow(folderWithCount: child, isSubfolder: true)
                                }
                            }
                        }
                    }
                }

                // Tags
                if !viewModel.tags.isEmpty {
                    Section("Tags") {
                        ForEach(viewModel.tags, id: \.tag.id) { tagWithCount in
                            NavigationLink {
                                TagDetailView(tagId: tagWithCount.tag.id!, tagName: tagWithCount.tag.name)
                            } label: {
                                TagRow(tagWithCount: tagWithCount)
                            }
                        }
                    }
                }

                // Trash
                Section {
                    NavigationLink {
                        TrashView()
                    } label: {
                        VirtualFolderRow(
                            icon: "trash.fill",
                            title: "Trash",
                            count: viewModel.trashedCount,
                            tintColor: .red
                        )
                    }
                }
            }
            .navigationTitle("Your notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        SearchView()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Menu {
                        Button {
                            showCreateNote = true
                        } label: {
                            Label("New Note", systemImage: "square.and.pencil")
                        }
                        Button {
                            showCreateFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Button {
                            showCreateTag = true
                        } label: {
                            Label("New Tag", systemImage: "tag")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateNote) {
                NoteEditorView(noteId: nil, folderId: nil)
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderSheet()
            }
            .sheet(isPresented: $showCreateTag) {
                CreateTagSheet()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
