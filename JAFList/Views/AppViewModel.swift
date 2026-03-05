//
//  AppViewModel.swift
//  JAFList

import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var appData: AppData
    @Published var syncStatus: SyncStatus = .idle
    private let dataStore: DataStore
    private var cancellables = Set<AnyCancellable>()

    init() {
        self.dataStore = DataStore()
        self.appData = dataStore.appData

        // Sync dataStore changes to viewModel
        dataStore.$appData
            .assign(to: &$appData)

        // Forward sync status
        dataStore.$syncStatus
            .assign(to: &$syncStatus)

        // Load cloud data after local data is ready
        Task {
            await dataStore.initializeCloud()
        }
    }

    // MARK: - Folder Operations

    func addFolder(name: String) {
        let newFolder = Folder(name: name)
        appData.folders.append(newFolder)
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    func deleteFolder(id: UUID) {
        appData.folders.removeAll { $0.id == id }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    // MARK: - Item Operations

    func addItem(to folderID: UUID, text: String, parentID: UUID? = nil) {
        guard let folderIndex = appData.folders.firstIndex(where: { $0.id == folderID }) else { return }

        let newItem = TodoItem(text: text)

        if let parentID = parentID {
            addChildItem(newItem, to: parentID, in: &appData.folders[folderIndex].items)
        } else {
            appData.folders[folderIndex].items.append(newItem)
        }

        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    private func addChildItem(_ item: TodoItem, to parentID: UUID, in items: inout [TodoItem]) {
        for i in items.indices {
            if items[i].id == parentID {
                items[i].children.append(item)
                items[i].isExpanded = true
                return
            }
            addChildItem(item, to: parentID, in: &items[i].children)
        }
    }

    func toggleItemCompletion(folderID: UUID, itemID: UUID) {
        guard let folderIndex = appData.folders.firstIndex(where: { $0.id == folderID }) else { return }

        toggleCompletion(itemID: itemID, in: &appData.folders[folderIndex].items)
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    private func toggleCompletion(itemID: UUID, in items: inout [TodoItem]) {
        for i in items.indices {
            if items[i].id == itemID {
                items[i].isCompleted.toggle()
                return
            }
            toggleCompletion(itemID: itemID, in: &items[i].children)
        }
    }

    func toggleItemExpansion(folderID: UUID, itemID: UUID) {
        guard let folderIndex = appData.folders.firstIndex(where: { $0.id == folderID }) else { return }

        toggleExpansion(itemID: itemID, in: &appData.folders[folderIndex].items)
        dataStore.appData = appData
        dataStore.saveLocalOnly()  // UI state only — don't update lastModified or sync
    }

    private func toggleExpansion(itemID: UUID, in items: inout [TodoItem]) {
        for i in items.indices {
            if items[i].id == itemID {
                items[i].isExpanded.toggle()
                return
            }
            toggleExpansion(itemID: itemID, in: &items[i].children)
        }
    }

    func editItem(folderID: UUID, itemID: UUID, newText: String) {
        guard let folderIndex = appData.folders.firstIndex(where: { $0.id == folderID }) else { return }
        editItemText(itemID: itemID, newText: newText, in: &appData.folders[folderIndex].items)
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    private func editItemText(itemID: UUID, newText: String, in items: inout [TodoItem]) {
        for i in items.indices {
            if items[i].id == itemID {
                items[i].text = newText
                return
            }
            editItemText(itemID: itemID, newText: newText, in: &items[i].children)
        }
    }

    func deleteItem(folderID: UUID, itemID: UUID) {
        guard let folderIndex = appData.folders.firstIndex(where: { $0.id == folderID }) else { return }

        deleteItem(itemID: itemID, from: &appData.folders[folderIndex].items)
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.save()
    }

    private func deleteItem(itemID: UUID, from items: inout [TodoItem]) {
        items.removeAll { $0.id == itemID }

        for i in items.indices {
            deleteItem(itemID: itemID, from: &items[i].children)
        }
    }

    // MARK: - Export

    func exportJSONFile() -> URL {
        dataStore.saveImmediately()
        return dataStore.fileURL
    }

    func saveOnBackground() {
        dataStore.saveImmediately()
    }
}
