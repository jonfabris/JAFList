//
//  FolderView.swift
//  JAFList

import SwiftUI

struct FolderView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var folder: Folder

    @State private var showingAddItemAlert = false
    @State private var newItemText = ""

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
            if folder.items.isEmpty {
                Text("No items yet")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(flatVisibleItems(from: folder.items), id: \.item.id) { entry in
                    TodoItemRow(item: entry.item, folderID: folder.id, depth: entry.depth)
                }
            }
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddItemAlert = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItemAlert, content: {
            AddItemView(newItemText: $newItemText) {
                viewModel.addItem(to: folder.id, text: newItemText)
                newItemText = ""
                showingAddItemAlert = false
            }
            .presentationDetents([.medium])
        }
        )
    }
}
