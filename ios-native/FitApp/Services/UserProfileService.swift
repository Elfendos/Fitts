import Foundation
import CloudKit

/// Replaces the Firestore-backed `UserProfileService` — mirrors
/// hooks/useUserProfile.ts, now reading/writing a single CKRecord
/// ("UserProfile", fixed recordID) in the private database instead of
/// Firestore's users/{uid} doc. CloudKit has no live listener API as
/// convenient as Firestore's `onSnapshot`; this polls-on-demand instead
/// (call `start()`/`refresh()`), which is fine for a single-record profile.
@MainActor
final class UserProfileService: ObservableObject {

    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let db = CloudKitManager.privateDatabase

    func start(isAccountAvailable: Bool) {
        guard isAccountAvailable else {
            profile = nil
            isLoading = false
            return
        }
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let record = try await db.record(for: UserProfile.recordID)
            profile = UserProfile(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            await createProfileIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func createProfileIfNeeded() async {
        // CloudKit doesn't expose the iCloud account's display name without
        // a separate Sign in with Apple step; default to "User" and let the
        // profile screen offer a rename (see ProfileView).
        let newProfile = UserProfile.newProfile(displayName: nil)
        let record = CKRecord(recordType: CloudKitRecordType.userProfile, recordID: UserProfile.recordID)
        newProfile.apply(to: record)
        do {
            try await db.save(record)
            profile = newProfile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetches the profile record, creating it on the spot if it doesn't
    /// exist yet — same fallback `updateProfile`/`setHealthProfile` need as
    /// DailyPlanService.save()/WorkoutPlanService.save() already have.
    /// Without this, calling either method before `createProfileIfNeeded()`
    /// has had a chance to run (or if that earlier save silently failed)
    /// threw `.unknownItem` and dropped every field the caller was trying
    /// to write — the onboarding flow's "start ediyor" bug: setHealthProfile
    /// failed silently, then the next `load()` re-created a blank profile.
    private func fetchOrCreateRecord() async -> CKRecord {
        if let existing = try? await db.record(for: UserProfile.recordID) {
            return existing
        }
        return CKRecord(recordType: CloudKitRecordType.userProfile, recordID: UserProfile.recordID)
    }

    func updateProfile(name: String? = nil, stats: UserStats? = nil) async -> Bool {
        do {
            let record = await fetchOrCreateRecord()
            var current = profile ?? UserProfile(record: record) ?? .newProfile(displayName: nil)
            if let name { current.name = name }
            if let stats { current.stats = stats }
            current.apply(to: record)
            try await db.save(record)
            profile = current
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func setHealthProfile(_ health: HealthProfile) async -> Bool {
        do {
            let record = await fetchOrCreateRecord()
            var current = profile ?? UserProfile(record: record) ?? .newProfile(displayName: nil)
            current.healthProfile = health
            current.apply(to: record)
            try await db.save(record)
            profile = current
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func stop() {
        // No-op: CloudKit fetches are one-shot here, unlike the Firestore
        // snapshot listener this replaces. Call `load()` again to refresh.
    }
}
