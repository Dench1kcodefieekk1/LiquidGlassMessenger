import Foundation
import Combine

/// Profile editing state with live validation.
final class ProfileViewModel: ObservableObject {
    @Published var firstName: String
    @Published var lastName: String
    @Published var username: String
    @Published var bio: String
    @Published var phoneNumber: String
    @Published var location: String
    @Published var dobEnabled: Bool
    @Published var dateOfBirth: Date

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    static let nameMaxLength = 64
    static let usernameMinLength = 3
    static let usernameMaxLength = 20
    static let bioMaxLength = 140
    static let locationMaxLength = 60

    init(appState: AppState) {
        self.appState = appState
        let profile = appState.profile
        // V3 split names; profiles saved by V2 fall back to splitting the
        // existing display name on its first space.
        if let first = profile.firstName {
            firstName = first
            lastName = profile.lastName ?? ""
        } else {
            let parts = profile.name.split(separator: " ", maxSplits: 1).map(String.init)
            firstName = parts.first ?? profile.name
            lastName = parts.count > 1 ? parts[1] : ""
        }
        username = profile.username
        bio = profile.bio
        phoneNumber = profile.phoneNumber ?? ""
        location = profile.location ?? ""
        dobEnabled = profile.dateOfBirth != nil
        dateOfBirth = profile.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    }

    /// Combined display name kept in sync with the split fields.
    var displayName: String {
        [firstName.trimmingCharacters(in: .whitespaces),
         lastName.trimmingCharacters(in: .whitespaces)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: Validation

    var firstNameError: String? {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "First name is required" }
        if trimmed.count > Self.nameMaxLength { return "First name is too long" }
        return nil
    }

    var lastNameError: String? {
        guard lastName.trimmingCharacters(in: .whitespacesAndNewlines).count <= Self.nameMaxLength else {
            return "Last name is too long"
        }
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

    var phoneError: String? {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let digits = trimmed.filter(\.isNumber)
        if digits.count < 6 { return "Phone number looks too short" }
        let allowed = CharacterSet(charactersIn: "+0123456789 -()")
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Use digits, spaces, +, - and () only"
        }
        return nil
    }

    var bioRemaining: Int {
        Self.bioMaxLength - bio.count
    }

    var isValid: Bool {
        firstNameError == nil
            && lastNameError == nil
            && usernameError == nil
            && phoneError == nil
            && bio.count <= Self.bioMaxLength
            && location.count <= Self.locationMaxLength
    }

    // MARK: Formatted display

    static let dobFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    var dateOfBirthLabel: String {
        Self.dobFormatter.string(from: dateOfBirth)
    }

    // MARK: Save

    /// Applies changes immediately and persists them.
    @discardableResult
    func save() -> Bool {
        guard isValid else { return false }
        var profile = appState.profile
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.firstName = first
        profile.lastName = last.isEmpty ? nil : last
        profile.name = displayName
        profile.username = username
        profile.bio = bio.trimmingCharacters(in: .whitespaces)
        let phone = phoneNumber.trimmingCharacters(in: .whitespaces)
        profile.phoneNumber = phone.isEmpty ? nil : phone
        let trimmedLocation = location.trimmingCharacters(in: .whitespaces)
        profile.location = trimmedLocation.isEmpty ? nil : trimmedLocation
        profile.dateOfBirth = dobEnabled ? dateOfBirth : nil
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
