import SwiftUI

/// Root container: ambient background, per-tab navigation stacks and the
/// floating glass navigation overlay.
struct RootView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var chatService: ChatService
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppColors.ambientBackground(light: colorScheme == .light)
                .ignoresSafeArea()

            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $router.selectedTab,
                           unreadBadge: chatService.totalUnread,
                           onCompose: { router.openCompose() })
        }
        .sheet(isPresented: $router.isComposePresented) {
            ComposeView()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch router.selectedTab {
        case .chats:
            NavigationStack(path: $router.chatsPath) {
                ChatListView()
                    .navigationDestination(for: String.self) { chatID in
                        ChatDetailView(chatID: chatID)
                    }
            }
        case .contacts:
            NavigationStack(path: $router.contactsPath) {
                ContactsView()
            }
        case .calls:
            NavigationStack(path: $router.callsPath) {
                CallsView()
            }
        case .settings:
            NavigationStack(path: $router.settingsPath) {
                SettingsView()
                    .navigationDestination(for: SettingsDestination.self) { destination in
                        settingsDestination(destination)
                    }
            }
        }
    }

    @ViewBuilder
    private func settingsDestination(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .appearance:
            AppearanceSettingsView()
        case .notifications:
            NotificationsSettingsView()
        case .privacy:
            PrivacySettingsView()
        case .dataStorage:
            DataStorageSettingsView()
        case .editProfile:
            EditProfileView()
        }
    }
}
