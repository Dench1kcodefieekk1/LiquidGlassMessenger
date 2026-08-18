import Foundation

/// A contact in the local address book (mock).
struct Contact: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var user: User
    var phoneNumber: String

    init(id: String = UUID().uuidString, user: User, phoneNumber: String = "") {
        self.id = id
        self.user = user
        self.phoneNumber = phoneNumber
    }
}
