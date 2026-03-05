//
//  AuthView.swift
//  JAFList

import SwiftUI
import GoogleSignInSwift

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("JAFList")
                .font(.largeTitle)
                .bold()

            if let errorMessage = authViewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                        .multilineTextAlignment(.leading)
                }
                .font(.footnote)
                .foregroundColor(.red)
                .padding(10)
                .frame(maxWidth: 280, alignment: .leading)
                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            if authViewModel.isLoading {
                ProgressView()
                    .frame(width: 280, height: 44)
            } else {
                GoogleSignInButton(scheme: .dark, style: .wide, state: .normal) {
                    Task { await authViewModel.signInWithGoogle() }
                }
                .frame(width: 280, height: 44)
            }

            Spacer()
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
