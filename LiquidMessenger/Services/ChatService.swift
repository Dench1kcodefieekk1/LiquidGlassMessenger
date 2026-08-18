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
    func updateLastMessage(_ message: Message, in chatID: String, incrementUnread: Bool)
}

/// Fully offline chat store seeded with mock data.
/// Pin/mute state is persisted; everything else lives in memory.
final class ChatService: ObservableObject, ChatServiceProtocol {
    @Published private(set) var chats: [Chat] = []

    init() {
        var seeded = MockData.makeChats()
        let pinned = PersistenceService.load([String].self, key: PersistenceKeys.pinnedChats) ?? []
        let muted = PersistenceService.load([String].self, key: PersistenceKeys.mutedChats) ?? []
        for index in seeded.indices {
            if pinned.contains(seeded[index].id) { seeded[index].isPinned = true }
            if muted.contains(seeded[index].id) { seeded[index].isMuted = true }
        }
        chats = seeded
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
        return chat
    }

    func togglePinned(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isPinned.toggle()
        persistPinned()
    }

    func toggleMuted(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isMuted.toggle()
        persistMuted()
    }

    func toggleArchived(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isArchived.toggle()
    }

    func delete(_ chatID: String) {
        chats.removeAll { $0.id == chatID }
    }

    func markRead(_ chatID: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].unreadCount = 0
    }

    func setTyping(_ chatID: String, _ isTyping: Bool) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].isTyping = isTyping
    }

    func updateLastMessage(_ message: Message, in chatID: String, incrementUnread: Bool = false) {
        guard let index = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[index].lastMessage = message
        if incrementUnread {
            chats[index].unreadCount += 1
        }
    }

    // MARK: Persistence

    private func persistPinned() {
        PersistenceService.save(chats.filter { $0.isPinned }.map { $0.id }, key: PersistenceKeys.pinnedChats)
    }

    private func persistMuted() {
        PersistenceService.save(chats.filter { $0.isMuted }.map { $0.id }, key: PersistenceKeys.mutedChats)
    }
}
