import Foundation

/// Small UserDefaults + Codable persistence helper (iOS 16 compatible).
enum PersistenceService {
    static let defaults = UserDefaults.standard

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(type, from: data) else { return nil }
        return value
    }

    static func remove(key: String) {
        defaults.removeObject(forKey: key)
    }
}

/// Centralized persistence keys.
enum PersistenceKeys {
    static let profile = "profile.v1"
    static let settings = "settings.v1"
    static let theme = "theme.v1"
    static let accent = "accent.v1"
    static let pinnedChats = "pinnedChats.v1"
    static let mutedChats = "mutedChats.v1"
}
