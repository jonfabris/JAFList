//
//  AuthViewModel.swift
//  JAFList

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isSignedIn = user != nil
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            try await FirebaseService.shared.signInWithGoogle()
        } catch {
            print(error)
            errorMessage = "Sign-in failed. Please try again."
        }
        isLoading = false
    }

    func signOut() {
        errorMessage = nil
        do {
            try FirebaseService.shared.signOut()
        } catch {
            print(error)
            errorMessage = "Sign-out failed. Please try again."
        }
    }
}
