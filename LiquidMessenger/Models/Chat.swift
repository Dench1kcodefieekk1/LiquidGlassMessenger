import Foundation

/// A conversation with a single peer in this app.
struct Chat: Identifiable, Codable, Equatable {
    /// Stable identifier of the permanent self-chat.
    static let savedMessagesID = "saved_messages"

    let id: String
    var peer: User
    var lastMessage: Message?
    var unreadCount: Int
    var isPinned: Bool
    var isMuted: Bool
    var isArchived: Bool
    var isTyping: Bool

    init(id: String = UUID().uuidString,
         peer: User,
         lastMessage: Message? = nil,
         unreadCount: Int = 0,
         isPinned: Bool = false,
         isMuted: Bool = false,
         isArchived: Bool = false,
         isTyping: Bool = false) {
        self.id = id
        self.peer = peer
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.isArchived = isArchived
        self.isTyping = isTyping
    }

    var sortedLastDate: Date { lastMessage?.date ?? .distantPast }

    /// The permanent "Saved Messages" self-chat (personal notes).
    var isSavedMessages: Bool { id == Chat.savedMessagesID }
}
