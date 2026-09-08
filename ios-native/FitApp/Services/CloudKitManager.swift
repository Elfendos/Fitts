import CloudKit

/// Central CloudKit access point. All data lives in the user's **private**
/// database — there's no server-side auth step the way Firebase needed one;
/// the private database is automatically scoped to whichever iCloud account
/// is signed in on the device.
///
/// Setup required (see ios-native/README.md):
///  1. Apple Developer account → the app's App ID needs the iCloud capability
///     with CloudKit enabled.
///  2. In Xcode → Signing & Capabilities → "+ Capability" → iCloud → check
///     "CloudKit" → make sure the container `iCloud.com.fitapp.workout`
///     is selected/created (project.yml already requests it via entitlements).
///  3. Nothing to configure server-side up front — CloudKit infers the
///     schema from the record types/fields the app saves on first run in
///     development, visible afterward in the CloudKit Dashboard.
enum CloudKitManager {
    static let containerIdentifier = "iCloud.com.fitapp.workout"
    static let container = CKContainer(identifier: containerIdentifier)
    static var privateDatabase: CKDatabase { container.privateCloudDatabase }
}

enum CloudKitRecordType {
    static let userProfile = "UserProfile"
    static let dailyPlan = "DailyPlan"
    static let workoutPlans = "WorkoutPlans"
    static let exerciseMaxWeights = "ExerciseMaxWeights"
}

enum CloudKitError: LocalizedError {
    case noAccount
    case restricted
    case couldNotDetermine
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .noAccount:
            return "Bu cihazda bir iCloud hesabı ile giriş yapılmamış. Ayarlar → [isim] → iCloud üzerinden giriş yap."
        case .restricted:
            return "iCloud erişimi kısıtlı (Ekran Zamanı/Aile ayarları)."
        case .couldNotDetermine:
            return "iCloud hesap durumu belirlenemedi. İnternet bağlantını kontrol et."
        case .decodeFailed:
            return "Veri okunamadı."
        }
    }
}
