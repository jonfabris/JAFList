//
//  ContentView.swift
//  JAFList

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showingAddFolderAlert = false
    @State private var newFolderName = ""

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
                            authViewModel.signOut()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFolderAlert = true
                    }) {
                        Image(systemName: "plus")
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
