//
//  AppViewModel.swift
//  JAFList

import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var appData: AppData
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date? = nil
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

        // Forward last sync date
        dataStore.$lastSyncDate
            .assign(to: &$lastSyncDate)

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
        dataStore.saveImmediately()
    }

    func deleteFolder(id: UUID) {
        appData.folders.removeAll { $0.id == id }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
    }

    // MARK: - Subfolder Operations

    func addSubfolder(to parentFolderID: UUID, name: String) {
        guard let idx = appData.folders.firstIndex(where: { $0.id == parentFolderID }) else { return }
        appData.folders[idx].subfolders.append(Folder(name: name))
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
    }

    func deleteSubfolder(parentFolderID: UUID, subfolderID: UUID) {
        guard let idx = appData.folders.firstIndex(where: { $0.id == parentFolderID }) else { return }
        appData.folders[idx].subfolders.removeAll { $0.id == subfolderID }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
    }

    func renameFolder(id: UUID, newName: String) {
        if let fi = appData.folders.firstIndex(where: { $0.id == id }) {
            appData.folders[fi].name = newName
        } else {
            for fi in appData.folders.indices {
                if let si = appData.folders[fi].subfolders.firstIndex(where: { $0.id == id }) {
                    appData.folders[fi].subfolders[si].name = newName
                    break
                }
            }
        }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
    }

    // MARK: - Item Operations

    /// Finds the items array for a given folder ID (top-level or subfolder) and runs an action on it.
    @discardableResult
    private func withFolderItems(folderID: UUID, action: (inout [TodoItem]) -> Void) -> Bool {
        if let fi = appData.folders.firstIndex(where: { $0.id == folderID }) {
            action(&appData.folders[fi].items)
            return true
        }
        for fi in appData.folders.indices {
            if let si = appData.folders[fi].subfolders.firstIndex(where: { $0.id == folderID }) {
                action(&appData.folders[fi].subfolders[si].items)
                return true
            }
        }
        return false
    }

    func addItem(to folderID: UUID, text: String, parentID: UUID? = nil) {
        let newItem = TodoItem(text: text)
        let found = withFolderItems(folderID: folderID) { items in
            if let parentID = parentID {
                self.addChildItem(newItem, to: parentID, in: &items)
            } else {
                items.append(newItem)
            }
        }
        guard found else { return }

        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
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
        let found = withFolderItems(folderID: folderID) { items in
            self.toggleCompletion(itemID: itemID, in: &items)
        }
        guard found else { return }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
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
        withFolderItems(folderID: folderID) { items in
            self.toggleExpansion(itemID: itemID, in: &items)
        }
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
        let found = withFolderItems(folderID: folderID) { items in
            self.editItemText(itemID: itemID, newText: newText, in: &items)
        }
        guard found else { return }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
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
        let found = withFolderItems(folderID: folderID) { items in
            self.removeItem(itemID: itemID, from: &items)
        }
        guard found else { return }
        appData.lastModified = Date()
        dataStore.appData = appData
        dataStore.saveImmediately()
    }

    private func removeItem(itemID: UUID, from items: inout [TodoItem]) {
        items.removeAll { $0.id == itemID }

        for i in items.indices {
            removeItem(itemID: itemID, from: &items[i].children)
        }
    }

    // MARK: - Backup & Restore

    func availableBackups() -> [BackupInfo] {
        BackupService.shared.listBackups()
    }

    func restore(from backup: BackupInfo) {
        dataStore.restore(from: backup)
    }

    // MARK: - Export

    func exportJSONFile() -> URL {
        dataStore.saveImmediately()
        return dataStore.fileURL
    }

    func syncWithCloud() async {
        await dataStore.initializeCloud()
    }

    func saveOnBackground() {
        dataStore.saveImmediately()
    }
}
