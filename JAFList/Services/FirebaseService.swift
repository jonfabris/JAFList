//
//  FirebaseService.swift
//  JAFList

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

class FirebaseService {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()

    private init() {}

    var currentUser: User? {
        Auth.auth().currentUser
    }

    // MARK: - Authentication

    @MainActor
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw FirebaseServiceError.configurationError
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = scene.keyWindow?.rootViewController else {
            throw FirebaseServiceError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw FirebaseServiceError.missingToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    // MARK: - Firestore

    func upload(_ appData: AppData) async throws {
        guard let uid = currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }

        let jsonData = try JSONService.encode(appData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw FirebaseServiceError.encodingFailed
        }

        print("[FirebaseService] upload() — uid: \(uid), dataSize: \(jsonString.count) chars")
        let docRef = db.collection("users").document(uid).collection("data").document("appdata")
        try await docRef.setData(["json": jsonString])
        print("[FirebaseService] upload() — success")
    }

    func download() async throws -> AppData? {
        guard let uid = currentUser?.uid else {
            throw FirebaseServiceError.notAuthenticated
        }

        print("[FirebaseService] download() — uid: \(uid)")
        let docRef = db.collection("users").document(uid).collection("data").document("appdata")
        let snapshot = try await docRef.getDocument(source: .server)

        print("[FirebaseService] snapshot.exists: \(snapshot.exists), fields: \(snapshot.data()?.keys.sorted() ?? [])")

        guard snapshot.exists, let jsonString = snapshot.data()?["json"] as? String else {
            return nil
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw FirebaseServiceError.decodingFailed
        }

        return try JSONService.decode(AppData.self, from: jsonData)
    }
}

enum FirebaseServiceError: LocalizedError {
    case configurationError
    case noRootViewController
    case missingToken
    case notAuthenticated
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .configurationError: return "Firebase configuration error."
        case .noRootViewController: return "Could not find a view controller to present sign-in."
        case .missingToken: return "Failed to get authentication token from Google."
        case .notAuthenticated: return "User is not authenticated."
        case .encodingFailed: return "Failed to encode app data."
        case .decodingFailed: return "Failed to decode app data."
        }
    }
}
