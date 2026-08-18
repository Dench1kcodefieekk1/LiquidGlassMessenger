import Foundation

/// Composition root: single shared service instances, created lazily once.
/// View models reference these directly; views receive them via the environment.
enum AppContainer {
    static let appState = AppState()
    static let haptics = HapticService()
    static let router = AppRouter()
    static let chatService = ChatService()
    static let messageService = MessageService(chatService: chatService)
    static let contactService = ContactService()
    static let callService = MockCallService()
    static let appViewModel = AppViewModel(state: appState)
}
