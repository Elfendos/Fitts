import SwiftUI

/// Replaces the Firebase magic-link login screen. CloudKit doesn't need an
/// in-app sign-in flow — it uses whichever iCloud account is already signed
/// in on the device — so this screen only shows up when that's *not* the
/// case, prompting the user to sign in via Settings.
struct LoginView: View {
    @EnvironmentObject private var account: CloudKitAccountService

    private var message: String {
        if case .unavailable(let error) = account.status {
            return error.localizedDescription
        }
        return "iCloud hesabı bulunamadı."
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("FitApp")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(AppTheme.brandAccent)
                Image(systemName: "icloud.slash")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.subtext)
            }

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.text)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Ayarlar'ı Aç")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(AppTheme.brandAccent)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Tekrar Dene") {
                    Task { await account.refresh() }
                }
                .foregroundColor(AppTheme.tint)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}
