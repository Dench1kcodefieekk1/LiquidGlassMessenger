import Foundation
import Combine

protocol ContactServiceProtocol: ObservableObject {
    var contacts: [Contact] { get }
    func addContact(name: String, phoneNumber: String, gradientIndex: Int)
    func openChat(for contact: Contact, using chatService: ChatService) -> String
}

/// Offline contact book seeded with mock data.
final class ContactService: ObservableObject, ContactServiceProtocol {
    @Published private(set) var contacts: [Contact] = []

    init() {
        contacts = MockData.makeContacts()
    }

    func addContact(name: String, phoneNumber: String, gradientIndex: Int) {
        let username = name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
        let user = User(id: "c_" + (username.isEmpty ? UUID().uuidString : username),
                        name: name,
                        username: username,
                        bio: "",
                        isOnline: false,
                        lastSeen: Date(),
                        gradientIndex: gradientIndex)
        contacts.append(Contact(user: user, phoneNumber: phoneNumber))
        contacts.sort { $0.user.name < $1.user.name }
    }

    /// Returns the chat ID for the contact, creating a conversation if needed.
    func openChat(for contact: Contact, using chatService: ChatService) -> String {
        chatService.createChat(with: contact.user).id
    }
}
