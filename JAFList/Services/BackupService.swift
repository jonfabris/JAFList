//
//  BackupService.swift
//  JAFList

import Foundation

struct BackupInfo: Identifiable {
    let url: URL
    let date: Date

    var id: URL { url }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

class BackupService {
    static let shared = BackupService()

    private let maxBackups = 8
    private let backupInterval: TimeInterval = 7 * 24 * 60 * 60
    private let lastBackupKey = "lastBackupDate"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func performAutoBackupIfNeeded(dataFileURL: URL) {
        let lastBackup = UserDefaults.standard.object(forKey: lastBackupKey) as? Date ?? .distantPast
        guard Date().timeIntervalSince(lastBackup) >= backupInterval else { return }
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else { return }
        createBackup(from: dataFileURL)
    }

    func createBackup(from dataFileURL: URL) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let backupURL = documentsURL.appendingPathComponent("jaflist_backup_\(timestamp).json")

        do {
            try FileManager.default.copyItem(at: dataFileURL, to: backupURL)
            UserDefaults.standard.set(Date(), forKey: lastBackupKey)
            pruneOldBackups()
        } catch {
            print("Backup failed: \(error)")
        }
    }

    func listBackups() -> [BackupInfo] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: documentsURL,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []
        return files
            .filter { $0.lastPathComponent.hasPrefix("jaflist_backup_") && $0.pathExtension == "json" }
            .compactMap { url -> BackupInfo? in
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let date = attrs?[.creationDate] as? Date ?? Date(timeIntervalSince1970: 0)
                return BackupInfo(url: url, date: date)
            }
            .sorted { $0.date > $1.date }
    }

    func restore(from backup: BackupInfo, to dataFileURL: URL) throws {
        if FileManager.default.fileExists(atPath: dataFileURL.path) {
            try FileManager.default.removeItem(at: dataFileURL)
        }
        try FileManager.default.copyItem(at: backup.url, to: dataFileURL)
    }

    private func pruneOldBackups() {
        let backups = listBackups()
        guard backups.count > maxBackups else { return }
        for backup in backups.suffix(from: maxBackups) {
            try? FileManager.default.removeItem(at: backup.url)
        }
    }
}
