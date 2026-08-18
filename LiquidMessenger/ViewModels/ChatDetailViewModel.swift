import Foundation
import Combine

/// Chat detail state: messages, reply mode, reactions, deletion.
final class ChatDetailViewModel: ObservableObject {
    let chatID: String

    @Published private(set) var messages: [Message] = []
    @Published var replyTarget: Message?
    @Published var pendingAttachment: MessageAttachment?

    private let messageService: MessageService
    private let chatService: ChatService
    private var cancellables = Set<AnyCancellable>()

    init(chatID: String, messageService: MessageService, chatService: ChatService) {
        self.chatID = chatID
        self.messageService = messageService
        self.chatService = chatService

        messageService.$store
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.messages = self.messageService.messages(for: self.chatID)
            }
            .store(in: &cancellables)

        messages = messageService.messages(for: chatID)
        chatService.markRead(chatID)
    }

    var peerName: String {
        chatService.chat(id: chatID)?.peer.name ?? "Unknown"
    }

    // MARK: Sending

    func send(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let attachment = pendingAttachment {
            messageService.send(attachment: attachment, in: chatID, peerName: peerName, replyTo: replyTarget)
            pendingAttachment = nil
        } else if !trimmed.isEmpty {
            messageService.send(text: trimmed, in: chatID, peerName: peerName, replyTo: replyTarget)
        } else {
            return
        }
        replyTarget = nil
    }

    func sendVoiceNote(duration: TimeInterval) {
        let attachment = MessageAttachment(kind: .voice, name: "voice_note.m4a", duration: duration)
        messageService.send(attachment: attachment, in: chatID, peerName: peerName, replyTo: replyTarget)
        replyTarget = nil
    }

    // MARK: Message actions

    func setReply(_ message: Message) {
        replyTarget = message
    }

    func cancelReply() {
        replyTarget = nil
    }

    func toggleReaction(_ emoji: String, on message: Message) {
        messageService.toggleReaction(emoji, on: message.id, in: chatID)
    }

    func delete(_ message: Message) {
        messageService.deleteMessage(message.id, in: chatID)
    }

    // MARK: Display list with date separators

    enum DisplayItem: Identifiable {
        case separator(id: String, label: String)
        case message(Message)

        var id: String {
            switch self {
            case .separator(let id, _): return id
            case .message(let message): return message.id
            }
        }
    }

    /// Messages interleaved with date separators (top → bottom order).
    var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        var previousDate: Date?
        for message in messages {
            if let previous = previousDate, TimeFormatting.isSameDay(previous, message.date) {
                // Same day, no separator needed.
            } else {
                items.append(.separator(id: "sep-\(message.id)",
                                        label: TimeFormatting.separatorLabel(for: message.date)))
            }
            items.append(.message(message))
            previousDate = message.date
        }
        return items
    }
}
