import SwiftUI

/// Settings hub: profile summary + category links.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ProfileView()
            .navigationTitle("Settings")
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @AppStorage(AppStorageKeys.appTheme) private var themeRaw = AppTheme.system.rawValue
    @AppStorage(AppStorageKeys.accentColor) private var accentRaw = AccentChoice.blue.rawValue
    @EnvironmentObject private var haptics: HapticService

    private var theme: AppTheme { AppTheme(rawValue: themeRaw) ?? .system }
    private var accent: AccentChoice { AccentChoice(rawValue: accentRaw) ?? .blue }

    var body: some View {
        Form {
            Section("Theme") {
                ForEach(AppTheme.allCases) { option in
                    Button {
                        themeRaw = option.rawValue
                        haptics.selection()
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 26)
                            Text(option.displayName)
                                .foregroundStyle(AppColors.primary)
                            Spacer()
                            if theme == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Accent Color") {
                HStack(spacing: AppSpacing.md) {
                    ForEach(AccentChoice.allCases) { choice in
                        Button {
                            accentRaw = choice.rawValue
                            haptics.selection()
                        } label: {
                            Circle()
                                .fill(choice.color)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(
                                        accent == choice ? Color.primary.opacity(0.6) : Color.clear,
                                        lineWidth: 2
                                    )
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .opacity(accent == choice ? 1 : 0)
                                )
                        }
                        .accessibilityLabel(choice.displayName)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xxs)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Notifications

struct NotificationsSettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Alerts") {
                Toggle("Messages", isOn: $appState.settings.notificationsMessages)
                Toggle("Groups", isOn: $appState.settings.notificationsGroups)
            }
            Section("Feedback") {
                Toggle("Sound", isOn: $appState.settings.notificationSound)
                Toggle("Vibration", isOn: $appState.settings.vibration)
                Toggle("Message Previews", isOn: $appState.settings.messagePreviews)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Visibility") {
                Picker("Last Seen", selection: $appState.settings.lastSeenVisibility) {
                    ForEach(LastSeenVisibility.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                Toggle("Profile Photo", isOn: $appState.settings.profilePhotoVisible)
            }
            Section {
                Toggle("Read Receipts", isOn: $appState.settings.readReceipts)
                Toggle("Passcode Lock", isOn: $appState.settings.passcodeLock)
            } header: {
                Text("Security")
            } footer: {
                Text("Passcode lock is a local mock setting in this demo.")
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data & Storage

struct DataStorageSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @StateObject private var vm = SettingsViewModel(appState: AppContainer.appState)

    var body: some View {
        Form {
            Section("Storage") {
                HStack {
                    Text("Storage Usage")
                        .foregroundStyle(AppColors.primary)
                    Spacer()
                    Text(vm.storageLabel)
                        .font(AppTypography.footnote.monospacedDigit())
                        .foregroundStyle(AppColors.secondary)
                }

                Button(role: .destructive) {
                    vm.clearCache()
                    haptics.success()
                } label: {
                    Text("Clear Cache")
                }
            }

            Section("Auto-Download") {
                Toggle("Photos", isOn: $appState.settings.autoDownloadPhotos)
                Toggle("Videos", isOn: $appState.settings.autoDownloadVideos)
                Toggle("Files", isOn: $appState.settings.autoDownloadFiles)
            }

            Section("Media Retention") {
                Picker("Keep Media", selection: $appState.settings.mediaRetention) {
                    ForEach(MediaRetention.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .navigationTitle("Data & Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}
