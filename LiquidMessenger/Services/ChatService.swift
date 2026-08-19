import Foundation
import Combine

protocol ChatServiceProtocol: ObservableObject {
    var chats: [Chat] { get }
    var totalUnread: Int { get }
    func chat(id: String) -> Chat?
    func existingChatID(withUserID userID: String) -> String?
    func createChat(with user: User) -> Chat
    func togglePinned(_ chatID: String)
    func toggleMuted(_ chatID: String)
    func toggleArchived(_ chatID: String)
    func delete(_ chatID: String)
    func markRead(_ chatID: String)
    func setTyping(_ chatID: String, _ isTyping: Bool)
    func updateLastMessage(_ message: Message?, in chatID: String, incrementUnread: Bool)
}

/// Chat store. V2 starts with a single permanent "Saved Messages" self-chat;
/// there are no seeded demo conversations. The full chat list is persisted
/// locally so conversations survive restarts.
final class ChatService: ObservableObject, ChatServiceProtocol {
    @Published private(set) var chats: [Chat] = []

    init() {
        if let stored = PersistenceService.load([Chat].self, key: PersistenceKeys.chats), !stored.isEmpty {
            chats = stored
        } else {
            chats = [Self.makeSavedMessagesChat()]
            persist()
        }
    }

    /// The permanent personal-notes conversation.
    static func makeSavedMessagesChat() -> Chat {
        Chat(id: Chat.savedMessagesID,
             peer: User(id: Chat.savedMessagesID,
                        name: "Saved Messages",
                        username: "saved",
                        isOnline: true,
                        gradientIndex: 0))
    }

    var totalUnread: Int {
        chats.filter { !$0.isArchived }.reduce(0) { $0 + $1.unreadCount }
    }

    func chat(id: String) -> Chat? {
        chats.first { $0.id == id }
    }

    func existingChatID(withUserID userID: String) -> String? {
        chats.first { $0.peer.id == userID }?.id
    }

    @discardableResult
    func createChat(with user: User) -> Chat {
        if let existing = chats.first(where: { $0.peer.id == user.id }) {
            if existing.isArchived {
                toggleArchived(existing.id)
            }
            return existing
        }
        let chat = Chat(peer: user)
        chats.insert(chat, at: 0)
        persist()
        return chat
    }

    func togglePinned(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isPinned.toggle()
        persist()
    }

    func toggleMuted(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isMuted.toggle()
        persist()
    }

    func toggleArchived(_ chatID: String) {
        guard chatID != Chat.savedMessagesID,
              let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isArchived.toggle()
        persist()
    }

    func delete(_ chatID: String) {
        guard chatID != Chat.savedMessagesID else { return }
        chats.removeAll { $0.id == chatID }
        AppContainer.messageService.removeMessages(in: chatID)
        persist()
    }

    func markRead(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }),
              chats[index].unreadCount != 0 else { return }
        chats[index].unreadCount = 0
        persist()
    }

    func setTyping(_ chatID: String, _ isTyping: Bool) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }),
              chats[index].isTyping != isTyping else { return }
        chats[index].isTyping = isTyping
    }

    func updateLastMessage(_ message: Message?, in chatID: String, incrementUnread: Bool = false) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].lastMessage = message
        if incrementUnread {
            chats[index].unreadCount += 1
        }
        persist()
    }

    // MARK: Persistence

    private func persist() {
        PersistenceService.save(chats, key: PersistenceKeys.chats)
    }
}
