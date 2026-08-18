import Foundation
import SwiftUI
import Combine

/// Appearance theme. Persisted and applied app-wide via `preferredColorScheme`.
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
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

/// Root observable app state: profile, theme, accent and settings.
final class AppState: ObservableObject {
    @Published var profile: User {
        didSet { PersistenceService.save(profile, key: PersistenceKeys.profile) }
    }
    @Published var theme: AppTheme {
        didSet { PersistenceService.save(theme, key: PersistenceKeys.theme) }
    }
    @Published var accent: AccentChoice {
        didSet { PersistenceService.save(accent, key: PersistenceKeys.accent) }
    }
    @Published var settings: AppSettings {
        didSet { PersistenceService.save(settings, key: PersistenceKeys.settings) }
    }

    init() {
        profile = PersistenceService.load(User.self, key: PersistenceKeys.profile) ?? MockData.defaultProfile
        theme = PersistenceService.load(AppTheme.self, key: PersistenceKeys.theme) ?? .system
        accent = PersistenceService.load(AccentChoice.self, key: PersistenceKeys.accent) ?? .blue
        settings = PersistenceService.load(AppSettings.self, key: PersistenceKeys.settings) ?? AppSettings()
    }
}

/// Thin wrapper exposing derived UI values from `AppState`.
final class AppViewModel: ObservableObject {
    @Published var state: AppState

    init(state: AppState) {
        self.state = state
        state.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    var theme: AppTheme { state.theme }
    var accentColor: Color { state.accent.color }
    var colorScheme: ColorScheme? { state.theme.colorScheme }
}
