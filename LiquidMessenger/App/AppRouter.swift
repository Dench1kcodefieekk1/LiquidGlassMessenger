import Foundation

/// Centralized navigation state for the four tabs.
final class AppRouter: ObservableObject {
    @Published var selectedTab: RootTab = .chats
    @Published var chatsPath: [String] = []
    @Published var contactsPath: [String] = []
    @Published var callsPath: [String] = []
    @Published var settingsPath: [SettingsDestination] = []
    @Published var isComposePresented = false
    /// Pushes PhoneNumberView on top of WelcomeView in the auth stack.
    @Published var isPhoneFlowPresented = false

    /// Opens a chat from anywhere in the app.
    func openChat(id: String) {
        selectedTab = .chats
        if !chatsPath.contains(id) {
            chatsPath.append(id)
        }
        isComposePresented = false
    }

    func openCompose() {
        isComposePresented = true
    }

    /// Clears all navigation state (used on logout).
    func resetNavigation() {
        selectedTab = .chats
        chatsPath = []
        contactsPath = []
        callsPath = []
        settingsPath = []
        isComposePresented = false
        isPhoneFlowPresented = false
    }
}

/// Destinations pushed inside the Settings navigation stack.
enum SettingsDestination: Hashable {
    case appearance
    case notifications
    case privacy
    case dataStorage
    case editProfile
}
