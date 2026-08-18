import SwiftUI

@main
struct LiquidMessengerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppContainer.appState)
                .environmentObject(AppContainer.appViewModel)
                .environmentObject(AppContainer.router)
                .environmentObject(AppContainer.chatService)
                .environmentObject(AppContainer.messageService)
                .environmentObject(AppContainer.contactService)
                .environmentObject(AppContainer.haptics)
                .tint(AppContainer.appViewModel.accentColor)
                .preferredColorScheme(AppContainer.appViewModel.colorScheme)
        }
    }
}
