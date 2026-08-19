import Foundation
import Combine

protocol MessageServiceProtocol: ObservableObject {
    func messages(for chatID: String) -> [Message]
    func send(text: String, in chatID: String, peerName: String, replyTo: Message?)
    func send(attachment: MessageAttachment, in chatID: String, peerName: String, replyTo: Message?)
    func toggleReaction(_ emoji: String, on messageID: String, in chatID: String)
    func deleteMessage(_ messageID: String, in chatID: String)
}

/// Local message store. V2 seeds no history: every conversation starts empty
/// and everything the user sends is persisted locally, so messages survive
/// app restarts. Saved Messages behaves as a pure self-chat (instant local
/// delivery, no simulated replies); peer chats keep the light delivery and
/// reply simulation so the messenger feels alive.
final class MessageService: ObservableObject, MessageServiceProtocol {

    @Published private(set) var store: [String: [Message]]

    private let chatService: ChatService
    private var sentCounter = 0

    init(chatService: ChatService) {
        self.chatService = chatService
        self.store = PersistenceService.load([String: [Message]].self,
                                             key: PersistenceKeys.messages) ?? [:]
    }

    func messages(for chatID: String) -> [Message] {
        store[chatID] ?? []
    }

    // MARK: Sending

    func send(text: String, in chatID: String, peerName: String, replyTo: Message?) {
        let message = Message(senderID: MockData.meID,
                              incoming: false,
                              kind: .text,
                              text: text,
                              date: Date(),
                              status: .sending,
                              replyToID: replyTo?.id,
                              replyPreview: replyTo?.preview)
        append(message, to: chatID)
        if chatID == Chat.savedMessagesID {
            // Self-chat: instantly "read by me", no simulation.
            setStatus(.read, of: message.id, in: chatID)
        } else {
            scheduleDelivery(of: message.id, in: chatID)
            maybeSimulateReply(in: chatID, peerName: peerName)
        }
    }

    func send(attachment: MessageAttachment, in chatID: String, peerName: String, replyTo: Message?) {
        let message = Message(senderID: MockData.meID,
                              incoming: false,
                              kind: attachment.kind,
                              text: "",
                              attachment: attachment,
                              date: Date(),
                              status: .sending,
                              replyToID: replyTo?.id,
                              replyPreview: replyTo?.preview)
        append(message, to: chatID)
        if chatID == Chat.savedMessagesID {
            setStatus(.read, of: message.id, in: chatID)
        } else {
            scheduleDelivery(of: message.id, in: chatID)
            maybeSimulateReply(in: chatID, peerName: peerName)
        }
    }

    // MARK: Reactions / deletion

    func toggleReaction(_ emoji: String, on messageID: String, in chatID: String) {
        guard var list = store[chatID],
              let index = list.firstIndex(where: { $0.id == messageID }) else { return }
        if let reactionIndex = list[index].reactions.firstIndex(where: { $0.emoji == emoji && $0.isFromMe }) {
            let count = list[index].reactions[reactionIndex].count
            if count <= 1 {
                list[index].reactions.remove(at: reactionIndex)
            } else {
                list[index].reactions[reactionIndex].count = count - 1
            }
        } else if let existingIndex = list[index].reactions.firstIndex(where: { $0.emoji == emoji }) {
            list[index].reactions[existingIndex].count += 1
            list[index].reactions[existingIndex].isFromMe = true
        } else {
            list[index].reactions.append(.init(emoji: emoji, isFromMe: true, count: 1))
        }
        store[chatID] = list
        persist()
    }

    func deleteMessage(_ messageID: String, in chatID: String) {
        store[chatID]?.removeAll { $0.id == messageID }
        if let last = store[chatID]?.last {
            chatService.updateLastMessage(last, in: chatID)
        } else {
            chatService.updateLastMessage(nil, in: chatID)
        }
        persist()
    }

    /// Removes all messages of a chat (used when a chat is deleted).
    func removeMessages(in chatID: String) {
        guard store[chatID] != nil else { return }
        store[chatID] = nil
        persist()
    }

    // MARK: Simulation

    private func append(_ message: Message, to chatID: String) {
        store[chatID, default: []].append(message)
        chatService.updateLastMessage(message, in: chatID)
        persist()
    }

    private func setStatus(_ status: MessageStatus, of messageID: String, in chatID: String) {
        guard let index = store[chatID]?.firstIndex(where: { $0.id == messageID }) else { return }
        store[chatID]?[index].status = status
        persist()
    }

    /// sending → sent → delivered, with an occasional failure to exercise the UI.
    private func scheduleDelivery(of messageID: String, in chatID: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            self.setStatus(.sent, of: messageID, in: chatID)
            try? await Task.sleep(nanoseconds: 800_000_000)
            if self.sentCounter % 7 == 6 {
                self.setStatus(.failed, of: messageID, in: chatID)
            } else {
                self.setStatus(.delivered, of: messageID, in: chatID)
            }
        }
    }

    /// Every other outgoing message triggers a simulated reply: typing indicator,
    /// incoming message, then read receipts on our messages.
    private func maybeSimulateReply(in chatID: String, peerName: String) {
        sentCounter += 1
        guard sentCounter % 2 == 0 else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard self.chatService.chat(id: chatID) != nil else { return }
            self.chatService.setTyping(chatID, true)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            self.chatService.setTyping(chatID, false)

            let reply = Message(senderID: chatID,
                                incoming: true,
                                kind: .text,
                                text: MockData.cannedReplies[Int.random(in: 0..<MockData.cannedReplies.count)],
                                date: Date(),
                                status: .read)
            self.append(reply, to: chatID)

            // Read receipts: everything we sent becomes "read".
            if let list = self.store[chatID] {
                for message in list where !message.incoming && message.status != .failed {
                    self.setStatus(.read, of: message.id, in: chatID)
                }
            }
        }
    }

    // MARK: Persistence

    private func persist() {
        PersistenceService.save(store, key: PersistenceKeys.messages)
    }
}
