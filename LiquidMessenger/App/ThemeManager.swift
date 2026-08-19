import SwiftUI

/// Centralized `@AppStorage` keys. These keys are the single source of truth
/// for session, theme and accent state, read and written by every screen.
enum AppStorageKeys {
    static let isLoggedIn = "isLoggedIn"
    static let appTheme = "appTheme"
    static let accentColor = "selectedAccentColor"
    /// V2 key, kept only to migrate the user's choice to `selectedAccentColor`.
    static let legacyAccentColor = "accentColor"
    static let selectedChatFolder = "selectedChatFolder"
}

/// Appearance theme. Persisted through `@AppStorage("appTheme")` and applied
/// globally at the app root via `.preferredColorScheme(...)`.
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

/// Persistable accent color. Persisted through `@AppStorage("selectedAccentColor")`
/// and applied globally via `.tint(...)` so every control updates live.
enum AccentChoice: String, Codable, CaseIterable, Identifiable {
    case blue, purple, pink, orange, green

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .orange: return .orange
        case .green: return .green
        }
    }

    var displayName: String { rawValue.capitalized }
}

/// Theme resolution helpers. There is exactly ONE theme source of truth:
/// the `appTheme` / `accentColor` keys in `UserDefaults` (via `@AppStorage`).
/// Views never compute the active scheme themselves — the app root applies it.
enum ThemeManager {
    static func colorScheme(for theme: AppTheme) -> ColorScheme? {
        theme.colorScheme
    }

    static func tint(for accent: AccentChoice) -> Color {
        accent.color
    }

    /// One-time migration from the V2 `accentColor` key to the V3
    /// `selectedAccentColor` key, preserving the user's choice.
    static func migrateLegacyAccentIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: AppStorageKeys.accentColor) == nil,
              let legacy = defaults.string(forKey: AppStorageKeys.legacyAccentColor) else { return }
        defaults.set(legacy, forKey: AppStorageKeys.accentColor)
        defaults.removeObject(forKey: AppStorageKeys.legacyAccentColor)
    }
}