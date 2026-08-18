import Foundation

/// Delivery / read lifecycle of an outgoing message.
enum MessageStatus: String, Codable, Equatable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

/// Content kind of a message.
enum MessageKind: String, Codable, Equatable {
    case text
    case image
    case video
    case file
    case voice
    case location
    case system
}

/// Lightweight attachment descriptor rendered inside bubbles.
struct MessageAttachment: Codable, Equatable, Hashable {
    var kind: MessageKind
    var name: String
    /// Seconds, for voice/video; `nil` otherwise.
    var duration: TimeInterval?
}

/// A single reaction on a message.
struct MessageReaction: Codable, Equatable, Hashable {
    var emoji: String
    var isFromMe: Bool
    var count: Int
}

/// A chat message. `incoming == false` means it was sent by the local user.
struct Message: Identifiable, Codable, Equatable {
    let id: String
    let senderID: String
    var incoming: Bool
    var kind: MessageKind
    var text: String
    var attachment: MessageAttachment?
    var date: Date
    var status: MessageStatus
    var reactions: [MessageReaction]
    var replyToID: String?
    var replyPreview: String?

    init(id: String = UUID().uuidString,
         senderID: String,
         incoming: Bool,
         kind: MessageKind = .text,
         text: String = "",
         attachment: MessageAttachment? = nil,
         date: Date = .init(),
         status: MessageStatus = .sent,
         reactions: [MessageReaction] = [],
         replyToID: String? = nil,
         replyPreview: String? = nil) {
        self.id = id
        self.senderID = senderID
        self.incoming = incoming
        self.kind = kind
        self.text = text
        self.attachment = attachment
        self.date = date
        self.status = status
        self.reactions = reactions
        self.replyToID = replyToID
        self.replyPreview = replyPreview
    }

    /// Short preview used in the chat list and reply banners.
    var preview: String {
        switch kind {
        case .text, .system: return text
        case .image: return "Photo"
        case .video: return "Video"
        case .file: return attachment?.name ?? "File"
        case .voice: return "Voice message"
        case .location: return "Location"
        }
    }
}
