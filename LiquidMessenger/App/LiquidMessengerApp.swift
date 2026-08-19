import SwiftUI

@main
struct LiquidMessengerApp: App {
    /// One source of truth for theme and accent: `@AppStorage` keys,
    /// applied globally at the root so every screen updates live.
    @AppStorage(AppStorageKeys.appTheme) private var themeRaw = AppTheme.system.rawValue
    @AppStorage(AppStorageKeys.accentColor) private var accentRaw = AccentChoice.blue.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }
    private var accent: AccentChoice { AccentChoice(rawValue: accentRaw) ?? .blue }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppContainer.appState)
                .environmentObject(AppContainer.router)
                .environmentObject(AppContainer.chatService)
                .environmentObject(AppContainer.messageService)
                .environmentObject(AppContainer.contactService)
                .environmentObject(AppContainer.haptics)
                .tint(ThemeManager.tint(for: accent))
                .preferredColorScheme(ThemeManager.colorScheme(for: theme))
        }
    }
}
