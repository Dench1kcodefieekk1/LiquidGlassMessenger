import Foundation

/// A user participating in conversations. The local profile is also a `User`.
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var username: String
    var bio: String
    var isOnline: Bool
    var lastSeen: Date
    /// Index into `AppColors.avatarGradients`, used to render the avatar.
    var gradientIndex: Int
    /// Phone number captured during authentication (V2).
    var phoneNumber: String?
    /// Free-form profile location, e.g. "Odesa, Ukraine" (V2).
    var location: String?
    /// Optional date of birth (V2).
    var dateOfBirth: Date?

    init(id: String = UUID().uuidString,
         name: String,
         username: String,
         bio: String = "",
         isOnline: Bool = false,
         lastSeen: Date = .init(),
         gradientIndex: Int = 0,
         phoneNumber: String? = nil,
         location: String? = nil,
         dateOfBirth: Date? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.bio = bio
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.gradientIndex = gradientIndex
        self.phoneNumber = phoneNumber
        self.location = location
        self.dateOfBirth = dateOfBirth
    }

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }
}
