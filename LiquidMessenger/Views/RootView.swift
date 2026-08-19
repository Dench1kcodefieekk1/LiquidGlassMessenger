import SwiftUI

/// Root container: session switch (auth flow vs main app), ambient
/// background, per-tab navigation stacks and the floating glass navigation.
struct RootView: View {
    /// Single session flag for the whole app, persisted across restarts.
    @AppStorage(AppStorageKeys.isLoggedIn) private var isLoggedIn = false

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var chatService: ChatService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.ambientBackground(light: colorScheme == .light)
                .ignoresSafeArea()

            if isLoggedIn {
                mainApp
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
            } else {
                authFlow
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.9), value: isLoggedIn)
    }

    // MARK: Auth flow

    /// Welcome → Phone → OTP, pushed inside a single navigation stack so
    /// transitions stay smooth and the back button works naturally.
    private var authFlow: some View {
        NavigationStack {
            WelcomeView()
                .navigationDestination(isPresented: Binding(
                    get: { router.isPhoneFlowPresented },
                    set: { router.isPhoneFlowPresented = $0 }
                )) {
                    PhoneNumberView()
                }
        }
    }

    // MARK: Main app

    private var mainApp: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Chat Detail hides the floating bar entirely (V3 §3):
                // the input bar becomes the only bottom UI in a chat.
                if !router.isTabBarHidden {
                    FloatingTabBar(selection: $router.selectedTab,
                                   unreadBadge: chatService.totalUnread,
                                   onCompose: { router.openCompose() })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.86),
                       value: router.isTabBarHidden)
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
        case .chatFolders:
            ChatFoldersView()
        case .devices:
            DevicesView()
        case .sharedMedia:
            SharedMediaView()
        case .editProfile:
            EditProfileView()
        }
    }
}
