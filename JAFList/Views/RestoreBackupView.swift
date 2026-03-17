//
//  RestoreBackupView.swift
//  JAFList

import SwiftUI

struct RestoreBackupView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var backups: [BackupInfo] = []
    @State private var confirmingBackup: BackupInfo? = nil

    var body: some View {
        NavigationStack {
            Group {
                if backups.isEmpty {
                    ContentUnavailableView(
                        "No Backups",
                        systemImage: "archivebox",
                        description: Text("Backups are created automatically once a week.")
                    )
                } else {
                    List(backups) { backup in
                        Button {
                            confirmingBackup = backup
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.blue)
                                Text(backup.displayName)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Restore Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                backups = viewModel.availableBackups()
            }
            .confirmationDialog(
                "Restore this backup?",
                isPresented: Binding(
                    get: { confirmingBackup != nil },
                    set: { if !$0 { confirmingBackup = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Restore", role: .destructive) {
                    if let backup = confirmingBackup {
                        viewModel.restore(from: backup)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    confirmingBackup = nil
                }
            } message: {
                if let backup = confirmingBackup {
                    Text("Your current data will be replaced with the backup from \(backup.displayName). This cannot be undone.")
                }
            }
        }
    }
}
