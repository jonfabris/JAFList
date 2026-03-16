//
//  FolderView.swift
//  JAFList

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var folder: Folder

    /// When non-nil, this view is showing a subfolder (no further nesting allowed).
    var parentFolderID: UUID? = nil

    var isSubfolder: Bool { parentFolderID != nil }

    @State private var showingAddItemSheet = false
    @State private var newItemText = ""
    @State private var showingAddSubfolderAlert = false
    @State private var newSubfolderName = ""
    @State private var showingRenameFolderAlert = false
    @State private var renameFolderText = ""
    @State private var renamingSubfolderID: UUID? = nil
    @State private var renameSubfolderText = ""

    private func flatVisibleItems(from items: [TodoItem], depth: Int = 0) -> [(item: TodoItem, depth: Int)] {
        var result: [(item: TodoItem, depth: Int)] = []
        for item in items {
            result.append((item, depth))
            if item.isExpanded && !item.children.isEmpty {
                result += flatVisibleItems(from: item.children, depth: depth + 1)
            }
        }
        return result
    }

    var body: some View {
        List {
            // Subfolder section — only shown for top-level folders
            if !isSubfolder {
                Section {
                    ForEach(folder.subfolders.indices, id: \.self) { index in
                        NavigationLink(destination: FolderView(
                            folder: Binding(
                                get: { folder.subfolders[index] },
                                set: { folder.subfolders[index] = $0 }
                            ),
                            parentFolderID: folder.id
                        )) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.orange)
                                Text(folder.subfolders[index].name)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteSubfolder(
                                    parentFolderID: folder.id,
                                    subfolderID: folder.subfolders[index].id
                                )
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                renamingSubfolderID = folder.subfolders[index].id
                                renameSubfolderText = folder.subfolders[index].name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    HStack {
                        Text("Folders")
                        Spacer()
                        Button {
                            showingAddSubfolderAlert = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                    }
                }
            }

            // Items section
            Section {
                if folder.items.isEmpty {
                    Text("No items yet")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(flatVisibleItems(from: folder.items), id: \.item.id) { entry in
                        TodoItemRow(item: entry.item, folderID: folder.id, depth: entry.depth)
                    }
                }
            } header: {
                Text("Items")
            }
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        renameFolderText = folder.name
                        showingRenameFolderAlert = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    Button(action: {
                        showingAddItemSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet, content: {
            AddItemView(newItemText: $newItemText) {
                viewModel.addItem(to: folder.id, text: newItemText)
                newItemText = ""
                showingAddItemSheet = false
            }
            .presentationDetents([.medium])
        })
        .alert("Add Folder", isPresented: $showingAddSubfolderAlert) {
            TextField("Folder name", text: $newSubfolderName)
            Button("Cancel", role: .cancel) {
                newSubfolderName = ""
            }
            Button("Add") {
                if !newSubfolderName.isEmpty {
                    viewModel.addSubfolder(to: folder.id, name: newSubfolderName)
                    newSubfolderName = ""
                }
            }
        }
        .alert("Rename Folder", isPresented: $showingRenameFolderAlert) {
            TextField("Folder name", text: $renameFolderText)
            Button("Cancel", role: .cancel) {
                renameFolderText = ""
            }
            Button("Rename") {
                if !renameFolderText.isEmpty {
                    viewModel.renameFolder(id: folder.id, newName: renameFolderText)
                }
                renameFolderText = ""
            }
        }
        .alert("Rename Folder", isPresented: Binding(
            get: { renamingSubfolderID != nil },
            set: { if !$0 { renamingSubfolderID = nil } }
        )) {
            TextField("Folder name", text: $renameSubfolderText)
            Button("Cancel", role: .cancel) {
                renamingSubfolderID = nil
                renameSubfolderText = ""
            }
            Button("Rename") {
                if let id = renamingSubfolderID, !renameSubfolderText.isEmpty {
                    viewModel.renameFolder(id: id, newName: renameSubfolderText)
                }
                renamingSubfolderID = nil
                renameSubfolderText = ""
            }
        }
    }
}
