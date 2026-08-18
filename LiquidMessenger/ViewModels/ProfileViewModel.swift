import Foundation
import Combine

/// Profile editing state with live validation.
final class ProfileViewModel: ObservableObject {
    @Published var name: String
    @Published var username: String
    @Published var bio: String

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    static let nameMaxLength = 64
    static let usernameMinLength = 3
    static let usernameMaxLength = 20
    static let bioMaxLength = 140

    init(appState: AppState) {
        self.appState = appState
        name = appState.profile.name
        username = appState.profile.username
        bio = appState.profile.bio
    }

    // MARK: Validation

    var nameError: String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Name is required" }
        if trimmed.count > Self.nameMaxLength { return "Name is too long" }
        return nil
    }

    var usernameError: String? {
        if username.count < Self.usernameMinLength { return "At least \(Self.usernameMinLength) characters" }
        if username.count > Self.usernameMaxLength { return "Maximum \(Self.usernameMaxLength) characters" }
        if username != username.lowercased() { return "Lowercase only" }
        if username.contains(" ") { return "No spaces allowed" }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if username.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Only letters, numbers and underscores"
        }
        return nil
    }

    var bioRemaining: Int {
        Self.bioMaxLength - bio.count
    }

    var isValid: Bool {
        nameError == nil && usernameError == nil && bio.count <= Self.bioMaxLength
    }

    // MARK: Save

    /// Applies changes immediately and persists them.
    @discardableResult
    func save() -> Bool {
        guard isValid else { return false }
        var profile = appState.profile
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.username = username
        profile.bio = bio.trimmingCharacters(in: .whitespaces)
        appState.profile = profile
        return true
    }

    /// Auto-sanitizes the username while typing (lowercase, allowed chars only).
    func sanitizeUsername() {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        var sanitized = username
            .lowercased()
            .filter { scalar in String(scalar).unicodeScalars.allSatisfy { allowed.contains($0) } }
        if sanitized.count > Self.usernameMaxLength {
            sanitized = String(sanitized.prefix(Self.usernameMaxLength))
        }
        if sanitized != username {
            username = sanitized
        }
    }
}
