//
//  DataStore.swift
//  JAFList
//

import Foundation
import Combine

enum SyncStatus {
    case idle
    case syncing
    case synced
    case offline
    case error
}

class DataStore: ObservableObject {
    @Published var appData: AppData
    @Published var syncStatus: SyncStatus = .idle

    private var saveTask: Task<Void, Never>?
    private let saveDebounceInterval: TimeInterval = 0.5

    var fileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("jaflist_data.json")
    }

    init() {
        self.appData = AppData.empty
        BackupService.shared.performAutoBackupIfNeeded(dataFileURL: fileURL)
        self.appData = load()
    }

    func load() -> AppData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppData.empty
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let loadedData = try JSONService.decode(AppData.self, from: data)
            return loadedData
        } catch {
            print("Error loading data: \(error)")
            return AppData.empty
        }
    }

    /// Saves to local file AND uploads to cloud. Call only for real content changes.
    /// The caller is responsible for setting appData.lastModified = Date() before calling.
    func save() {
        saveTask?.cancel()

        saveTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(saveDebounceInterval * 1_000_000_000))

            guard !Task.isCancelled else { return }

            do {
                let dataToSave = self.appData
                let jsonData = try JSONService.encode(dataToSave)
                try jsonData.write(to: fileURL, options: .atomic)

                await MainActor.run { self.syncStatus = .syncing }

                try await FirebaseService.shared.upload(dataToSave)

                await MainActor.run { self.syncStatus = .synced }
            } catch is CancellationError {
                // Task was cancelled; no-op
            } catch {
                print("Error saving data: \(error)")
                await MainActor.run { self.syncStatus = .offline }
            }
        }
    }

    /// Saves to local file only. Does NOT update lastModified or upload to cloud.
    /// Use for UI-only state changes (e.g. expand/collapse) that should not affect sync.
    func saveLocalOnly() {
        do {
            let jsonData = try JSONService.encode(appData)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving local data: \(error)")
        }
    }

    func saveImmediately() {
        saveTask?.cancel()

        do {
            let jsonData = try JSONService.encode(appData)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving data: \(error)")
        }

        Task {
            try? await FirebaseService.shared.upload(self.appData)
        }
    }

    func restore(from backup: BackupInfo) {
        do {
            try BackupService.shared.restore(from: backup, to: fileURL)
            appData = load()
        } catch {
            print("Restore failed: \(error)")
        }
    }

    func initializeCloud() async {
        do {
            guard let cloudData = try await FirebaseService.shared.download() else {
                // No cloud data yet — upload local data to seed Firestore for other devices
                if appData.lastModified > Date(timeIntervalSince1970: 0) {
                    try await FirebaseService.shared.upload(appData)
                }
                await MainActor.run { self.syncStatus = .synced }
                return
            }

            let localData = appData
            let dataToUse = cloudData.lastModified > localData.lastModified ? cloudData : localData

            // If cloud data is newer, update local file
            if cloudData.lastModified > localData.lastModified {
                let jsonData = try JSONService.encode(dataToUse)
                try jsonData.write(to: fileURL, options: .atomic)
                await MainActor.run { self.appData = dataToUse }
            }

            // If local data is newer, push it to cloud
            if localData.lastModified > cloudData.lastModified {
                try await FirebaseService.shared.upload(localData)
            }

            await MainActor.run { self.syncStatus = .synced }
        } catch {
            print("Cloud initialization error: \(error)")
            await MainActor.run { self.syncStatus = .offline }
        }
    }
}
