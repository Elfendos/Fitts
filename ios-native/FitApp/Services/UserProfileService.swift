import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Mirrors hooks/useUserProfile.ts — Firestore path: users/{uid}.
/// Live-updates via a snapshot listener and auto-creates the profile
/// document on first sign-in, exactly like the RN hook.
@MainActor
final class UserProfileService: ObservableObject {

    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = true

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func start(for uid: String?) {
        listener?.remove()
        guard let uid else {
            profile = nil
            isLoading = false
            return
        }

        isLoading = true
        let ref = db.collection("users").document(uid)

        listener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    print("User profile listener error: \(error)")
                    self.isLoading = false
                    return
                }
                guard let snapshot, snapshot.exists else {
                    await self.createProfileIfNeeded(uid: uid)
                    return
                }
                self.profile = try? snapshot.data(as: UserProfile.self)
                self.isLoading = false
            }
        }
    }

    private func createProfileIfNeeded(uid: String) async {
        let currentUser = Auth.auth().currentUser
        let newProfile = UserProfile.newProfile(
            uid: uid,
            email: currentUser?.email,
            displayName: currentUser?.displayName
        )
        do {
            try db.collection("users").document(uid).setData(from: newProfile, merge: true)
            self.profile = newProfile
        } catch {
            print("Failed to create user profile: \(error)")
        }
        self.isLoading = false
    }

    func updateProfile(_ fields: [String: Any]) async -> Bool {
        guard let uid = profile?.uid else { return false }
        do {
            var payload = fields
            payload["updatedAt"] = FieldValue.serverTimestamp()
            try await db.collection("users").document(uid).updateData(payload)
            return true
        } catch {
            print("Update profile error: \(error)")
            return false
        }
    }

    func setHealthProfile(_ health: HealthProfile) async -> Bool {
        guard let uid = profile?.uid else { return false }
        do {
            let data = try Firestore.Encoder().encode(health)
            try await db.collection("users").document(uid).updateData([
                "healthProfile": data,
                "updatedAt": FieldValue.serverTimestamp(),
            ])
            return true
        } catch {
            print("Set health profile error: \(error)")
            return false
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }
}
