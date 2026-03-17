//
//  TodoItemRow.swift
//  JAFList

import SwiftUI

struct TodoItemRow: View {
    @EnvironmentObject var viewModel: AppViewModel
    let item: TodoItem
    let folderID: UUID
    let depth: Int

    @State private var showingAddSubitemAlert = false
    @State private var newSubitemText = ""
    @State private var isEditing = false
    @State private var editText = ""
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Checkbox
                Button(action: {
                    viewModel.toggleItemCompletion(folderID: folderID, itemID: item.id)
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundColor(item.isCompleted ? .green : .gray)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())

                // Text / inline edit
                if isEditing {
                    TextField("", text: $editText)
                        .focused($textFieldFocused)
                        .onSubmit { commitEdit() }
                        .onChange(of: textFieldFocused) { _, focused in
                            if !focused { commitEdit() }
                        }
                } else {
                    Text(item.text)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .gray : .primary)
                        .onTapGesture {
                            editText = item.text
                            isEditing = true
                            textFieldFocused = true
                        }
                }

                Spacer()

                // Disclosure indicator
                if !item.children.isEmpty {
                    Image(systemName: item.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
            .padding(.leading, CGFloat(depth) * 20)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                if !item.children.isEmpty {
                    viewModel.toggleItemExpansion(folderID: folderID, itemID: item.id)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    viewModel.deleteItem(folderID: folderID, itemID: item.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    showingAddSubitemAlert = true
                } label: {
                    Label("Add Subitem", systemImage: "plus.circle")
                }
                .tint(.blue)
            }

        }
        .alert("Add Subitem", isPresented: $showingAddSubitemAlert) {
            TextField("Subitem text", text: $newSubitemText)
            Button("Cancel", role: .cancel) {
                newSubitemText = ""
            }
            Button("Add") {
                if !newSubitemText.isEmpty {
                    viewModel.addItem(to: folderID, text: newSubitemText, parentID: item.id)
                    newSubitemText = ""
                }
            }
        }
    }

    private func commitEdit() {
        isEditing = false
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != item.text else { return }
        viewModel.editItem(folderID: folderID, itemID: item.id, newText: trimmed)
    }
}

#Preview("TodoItemRow") {
    let folderID = UUID()
    let item = TodoItem(
        text: "Buy groceries",
        isExpanded: true,
        children: [
            TodoItem(text: "Milk"),
            TodoItem(text: "Eggs", isCompleted: true)
        ]
    )
    List {
        TodoItemRow(item: item, folderID: folderID, depth: 0)
        TodoItemRow(item: TodoItem(text: "Completed task", isCompleted: true), folderID: folderID, depth: 0)
        TodoItemRow(item: TodoItem(text: "Nested subitem"), folderID: folderID, depth: 1)
    }
    .environmentObject(AppViewModel())
}
