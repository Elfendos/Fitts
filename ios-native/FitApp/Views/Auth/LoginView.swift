import SwiftUI

/// Mirrors app/(auth)/login.tsx — passwordless "magic link" email sign-in.
/// After requesting a link, the user checks their inbox; tapping the link
/// reopens the app via `onOpenURL` (see FitAppApp.swift) which completes
/// the sign-in through AuthService.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var email = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var linkSent = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("FitApp")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppTheme.brandAccent)
                Text(L("auth.welcome"))
                    .font(.title3)
                    .foregroundColor(AppTheme.subtext)
            }

            if linkSent {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.tint)
                    Text("\(email) adresine bir giriş linki gönderildi.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.text)
                    Button(L("common.back")) {
                        linkSent = false
                    }
                    .foregroundColor(AppTheme.tint)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    TextField(L("auth.email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(AppTheme.cardBackground)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
                        .cornerRadius(12)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await sendLink() }
                    } label: {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text(L("auth.login"))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.brandAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(email.isEmpty || isSending)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func sendLink() async {
        errorMessage = nil
        isSending = true
        let result = await auth.sendLoginLink(to: email)
        isSending = false
        if result.success {
            linkSent = true
        } else {
            errorMessage = result.errorMessage
        }
    }
}
