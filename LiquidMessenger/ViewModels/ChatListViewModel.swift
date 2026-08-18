import Foundation
import Combine

/// Chat list state: filtering with debounced search, sections, swipe actions.
final class ChatListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var filteredChats: [Chat] = []
    @Published var showArchived = false

    private let chatService: ChatService
    private var cancellables = Set<AnyCancellable>()
    private let searchSubject = PassthroughSubject<String, Never>()

    init(chatService: ChatService) {
        self.chatService = chatService
        filteredChats = chatService.chats

        // Rebuild when the underlying chats change.
        chatService.$chats
            .receive(on: RunLoop.main)
            .sink { [weak self] chats in
                guard let self else { return }
                self.filteredChats = self.applyFilter(to: chats, query: self.searchText)
            }
            .store(in: &cancellables)

        // Debounced search: avoid expensive filtering on every keystroke.
        searchSubject
            .debounce(for: .milliseconds(220), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                self.filteredChats = self.applyFilter(to: self.chatService.chats, query: query)
            }
            .store(in: &cancellables)
    }

    func searchTextChanged(_ text: String) {
        searchText = text
        searchSubject.send(text)
    }

    // MARK: Derived sections

    var visibleChats: [Chat] {
        showArchived
            ? filteredChats.filter { $0.isArchived }
            : filteredChats.filter { !$0.isArchived }
    }

    var pinnedChats: [Chat] {
        visibleChats.filter { $0.isPinned }.sorted { $0.sortedLastDate > $1.sortedLastDate }
    }

    var regularChats: [Chat] {
        visibleChats.filter { !$0.isPinned }.sorted { $0.sortedLastDate > $1.sortedLastDate }
    }

    var archivedCount: Int {
        chatService.chats.filter { $0.isArchived }.count
    }

    // MARK: Actions

    func togglePinned(_ chat: Chat) { chatService.togglePinned(chat.id) }
    func toggleMuted(_ chat: Chat) { chatService.toggleMuted(chat.id) }
    func toggleArchived(_ chat: Chat) { chatService.toggleArchived(chat.id) }
    func delete(_ chat: Chat) { chatService.delete(chat.id) }

    /// Opens an existing chat with the contact or creates a new one.
    func startChat(with user: User) -> String {
        chatService.createChat(with: user).id
    }

    // MARK: Filtering

    private func applyFilter(to chats: [Chat], query: String) -> [Chat] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return chats }
        let lowered = trimmed.lowercased()
        return chats.filter { chat in
            chat.peer.name.lowercased().contains(lowered)
                || chat.peer.username.lowercased().contains(lowered)
                || (chat.lastMessage?.preview.lowercased().contains(lowered) ?? false)
        }
    }
}
