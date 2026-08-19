import Foundation
import Combine

/// All user-facing settings. Persisted as a single Codable blob.
struct AppSettings: Codable, Equatable {
    var notificationsMessages = true
    var notificationsGroups = true
    var notificationSound = true
    var vibration = true
    var messagePreviews = true

    var lastSeenVisibility: LastSeenVisibility = .everybody
    var profilePhotoVisible = true
    var readReceipts = true
    var passcodeLock = false

    var autoDownloadPhotos = true
    var autoDownloadVideos = false
    var autoDownloadFiles = false
    var mediaRetention: MediaRetention = .threeMonths
}

enum LastSeenVisibility: String, Codable, CaseIterable {
    case everybody = "Everybody"
    case contacts = "My Contacts"
    case nobody = "Nobody"
}

enum MediaRetention: String, Codable, CaseIterable {
    case forever = "Forever"
    case threeMonths = "3 Months"
    case oneMonth = "1 Month"
    case oneWeek = "1 Week"
}

/// Root observable app state: profile and settings.
/// Theme/accent live in `@AppStorage` (see ThemeManager); the session flag
/// lives in `@AppStorage("isLoggedIn")` — each has exactly one source of truth.
final class AppState: ObservableObject {
    @Published var profile: User {
        didSet { PersistenceService.save(profile, key: PersistenceKeys.profile) }
    }
    @Published var settings: AppSettings {
        didSet { PersistenceService.save(settings, key: PersistenceKeys.settings) }
    }

    init() {
        profile = PersistenceService.load(User.self, key: PersistenceKeys.profile) ?? MockData.defaultProfile
        settings = PersistenceService.load(AppSettings.self, key: PersistenceKeys.settings) ?? AppSettings()
    }
}
