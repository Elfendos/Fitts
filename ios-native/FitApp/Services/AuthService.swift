import Foundation
import FirebaseAuth

/// Mirrors context/AuthContext.tsx — passwordless email link ("magic link") sign-in.
///
/// Setup required in Firebase console + Xcode (mirrors RN's ACTION_CODE_SETTINGS):
///  1. Firebase console → Authentication → Sign-in method → enable "Email link (passwordless sign-in)".
///  2. Authentication → Settings → Authorized domains → add your Firebase authDomain.
///  3. Add the `fitapp://` custom URL scheme in project.yml (already done) so the app can
///     be reopened from the emailed link if you configure a dynamic link / universal link
///     that redirects into it. For a pure custom-scheme flow, set `handleCodeInApp = true`
///     and point the continue URL at your own simple redirect page.
@MainActor
final class AuthService: ObservableObject {

    @Published private(set) var user: User?
    @Published private(set) var isLoading = true

    private var handle: AuthStateDidChangeListenerHandle?
    private let pendingEmailKey = "fitapp.auth.pendingEmail"

    /// Must match an authorized domain in your Firebase project.
    private let authDomain = Bundle.main.object(forInfoDictionaryKey: "FirebaseAuthDomain") as? String
        ?? "fitapp.firebaseapp.com"

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            self?.user = firebaseUser
            self?.isLoading = false
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private var actionCodeSettings: ActionCodeSettings {
        let settings = ActionCodeSettings()
        settings.url = URL(string: "https://\(authDomain)/?finishSignIn=true")
        settings.handleCodeInApp = true
        settings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "com.fitapp.workout")
        return settings
    }

    struct AuthResult {
        var success: Bool
        var errorMessage: String?
    }

    func sendLoginLink(to email: String) async -> AuthResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await Auth.auth().sendSignInLink(toEmail: trimmed, actionCodeSettings: actionCodeSettings)
            UserDefaults.standard.set(trimmed, forKey: pendingEmailKey)
            return AuthResult(success: true, errorMessage: nil)
        } catch {
            return AuthResult(success: false, errorMessage: message(for: error))
        }
    }

    var pendingEmail: String? {
        UserDefaults.standard.string(forKey: pendingEmailKey)
    }

    func clearPendingEmail() {
        UserDefaults.standard.removeObject(forKey: pendingEmailKey)
    }

    @discardableResult
    func completeSignIn(fromLink link: String) async -> AuthResult {
        guard Auth.auth().isSignIn(withEmailLink: link) else {
            return AuthResult(success: false, errorMessage: "Bu bir giriş linki değil.")
        }
        guard let email = pendingEmail else {
            return AuthResult(
                success: false,
                errorMessage: "E-posta bulunamadı. Lütfen aynı cihazda yeni bir link iste."
            )
        }
        do {
            try await Auth.auth().signIn(withEmail: email, link: link)
            clearPendingEmail()
            return AuthResult(success: true, errorMessage: nil)
        } catch {
            return AuthResult(success: false, errorMessage: message(for: error))
        }
    }

    func handleIncomingURL(_ url: URL) async {
        let link = url.absoluteString
        guard Auth.auth().isSignIn(withEmailLink: link) else { return }
        _ = await completeSignIn(fromLink: link)
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            clearPendingEmail()
        } catch {
            print("Sign out error: \(error)")
        }
    }

    private func message(for error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .invalidEmail:
            return "Geçersiz e-posta adresi."
        case .unauthorizedDomain:
            return "Yetkisiz domain. Firebase ayarlarını kontrol edin."
        case .invalidActionCode:
            return "Link geçersiz veya zaten kullanılmış."
        case .expiredActionCode:
            return "Linkin süresi dolmuş, yeni bir link iste."
        default:
            return "İşlem başarısız. Lütfen tekrar deneyin."
        }
    }
}
