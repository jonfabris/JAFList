//
//  JAFListApp.swift
//  JAFList

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct JAFListApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isSignedIn {
                    ContentView()
                        .environmentObject(viewModel)
                        .environmentObject(authViewModel)
                } else {
                    AuthView()
                        .environmentObject(authViewModel)
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel.saveOnBackground()
            }
        }
    }
}
