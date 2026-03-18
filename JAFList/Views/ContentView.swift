//
//  ContentView.swift
//  JAFList

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showingAddFolderAlert = false
    @State private var newFolderName = ""
    @State private var renamingFolderID: UUID? = nil
    @State private var renameFolderText = ""
    @State private var showingRestoreSheet = false
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.appData.folders.isEmpty {
                    Text("No folders yet")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(viewModel.appData.folders.indices, id: \.self) { index in
                        NavigationLink(destination: FolderView(
                            folder: Binding(
                                get: { viewModel.appData.folders[index] },
                                set: { viewModel.appData.folders[index] = $0 }
                            )
                        )) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.blue)
                                Text(viewModel.appData.folders[index].name)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteFolder(id: viewModel.appData.folders[index].id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                renamingFolderID = viewModel.appData.folders[index].id
                                renameFolderText = viewModel.appData.folders[index].name
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
            .navigationTitle("JAFList")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        syncStatusIcon

                        Button {
                            showingSignOutConfirmation = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        
                        Button {
                            showingRestoreSheet = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            showingAddFolderAlert = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("Add Folder", isPresented: $showingAddFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
                Button("Add") {
                    if !newFolderName.isEmpty {
                        viewModel.addFolder(name: newFolderName)
                        newFolderName = ""
                    }
                }
            }
            .alert("Rename Folder", isPresented: Binding(
                get: { renamingFolderID != nil },
                set: { if !$0 { renamingFolderID = nil } }
            )) {
                TextField("Folder name", text: $renameFolderText)
                Button("Cancel", role: .cancel) {
                    renamingFolderID = nil
                    renameFolderText = ""
                }
                Button("Rename") {
                    if let id = renamingFolderID, !renameFolderText.isEmpty {
                        viewModel.renameFolder(id: id, newName: renameFolderText)
                    }
                    renamingFolderID = nil
                    renameFolderText = ""
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showingRestoreSheet) {
                RestoreBackupView()
                    .environmentObject(viewModel)
            }
            .safeAreaInset(edge: .bottom) {
                if let date = viewModel.lastSyncDate {
                    Text("Last synced: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.bar)
                }
            }
        }
    }

    @ViewBuilder
    private var syncStatusIcon: some View {
        switch viewModel.syncStatus {
        case .idle:
            EmptyView()
        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)
                .symbolEffect(.rotate, isActive: true)
        case .synced:
            Image(systemName: "cloud.fill")
                .foregroundColor(.green)
        case .offline:
            Image(systemName: "cloud.slash")
                .foregroundColor(.orange)
        case .error:
            Image(systemName: "cloud.slash")
                .foregroundColor(.red)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
        .environmentObject(AuthViewModel())
}
