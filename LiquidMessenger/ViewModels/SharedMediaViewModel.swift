import Foundation
import Combine

/// A URL extracted from a real sent/received message (V3 §35).
struct SharedLink: Identifiable, Equatable {
    let id: String
    let url: URL
    let date: Date
}

/// Derives the Shared Media sections (Photos / Files / Links) from the
/// actual local message store — never from invented demo content.
final class SharedMediaViewModel: ObservableObject {
    @Published private(set) var photos: [Message] = []
    @Published private(set) var files: [Message] = []
    @Published private(set) var links: [SharedLink] = []

    private var cancellable: AnyCancellable?

    /// One reusable detector — never rebuilt per message (V3 §46).
    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    init(messageService: MessageService) {
        recompute(from: messageService.store)
        cancellable = messageService.$store
            .receive(on: RunLoop.main)
            .sink { [weak self] store in
                self?.recompute(from: store)
            }
    }

    private func recompute(from store: [String: [Message]]) {
        let all = store.values.flatMap { $0 }.sorted { $0.date < $1.date }
        photos = all.filter { $0.kind == .image || $0.kind == .video }
        files = all.filter { $0.kind == .file }
        links = Self.extractLinks(from: all)
    }

    /// Extracts every real URL from message text using the system detector.
    private static func extractLinks(from messages: [Message]) -> [SharedLink] {
        var seen = Set<String>()
        var result: [SharedLink] = []
        for message in messages where !message.text.isEmpty {
            let range = NSRange(message.text.startIndex..., in: message.text)
            guard let matches = linkDetector?.matches(in: message.text, options: [], range: range) else { continue }
            for match in matches {
                guard match.resultType == .link, let url = match.url else { continue }
                let normalized = url.absoluteString.lowercased()
                guard !seen.contains(normalized) else { continue }
                seen.insert(normalized)
                result.append(SharedLink(id: message.id + normalized, url: url, date: message.date))
            }
        }
        return result
    }
}
