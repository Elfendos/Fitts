import Foundation
import CloudKit

/// Replaces the Firebase `AuthService` (context/AuthContext.tsx). There's no
/// email/password/magic-link flow anymore: CloudKit's private database is
/// automatically scoped to the iCloud account already signed in on the
/// device, so "auth" here just means "is iCloud available".
@MainActor
final class CloudKitAccountService: ObservableObject {

    enum Status: Equatable {
        case checking
        case available
        case unavailable(CloudKitError)
    }

    @Published private(set) var status: Status = .checking
    @Published private(set) var userRecordID: CKRecord.ID?

    var isLoading: Bool { status == .checking }
    var isAvailable: Bool { status == .available }

    init() {
        Task { await refresh() }

        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func refresh() async {
        status = .checking
        do {
            let accountStatus = try await CloudKitManager.container.accountStatus()
            switch accountStatus {
            case .available:
                userRecordID = try? await CloudKitManager.container.userRecordID()
                status = .available
            case .noAccount:
                status = .unavailable(.noAccount)
            case .restricted, .temporarilyUnavailable:
                status = .unavailable(.restricted)
            case .couldNotDetermine:
                fallthrough
            @unknown default:
                status = .unavailable(.couldNotDetermine)
            }
        } catch {
            status = .unavailable(.couldNotDetermine)
        }
    }
}
