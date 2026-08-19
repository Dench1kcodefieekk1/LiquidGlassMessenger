import SwiftUI

/// Telegram-style My Profile card + entry points into settings categories.
struct ProfileView: View {
    @AppStorage(AppStorageKeys.isLoggedIn) private var isLoggedIn = true
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var haptics: HapticService
    @State private var confirmLogout = false

    var body: some View {
        List {
            Section {
                profileCard
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section("Info") {
                infoRow(icon: "person", title: "First Name", value: appState.profile.firstName ?? appState.profile.name)
                if let lastName = appState.profile.lastName, !lastName.isEmpty {
                    infoRow(icon: "person.2", title: "Last Name", value: lastName)
                }
                if let phone = appState.profile.phoneNumber, !phone.isEmpty {
                    infoRow(icon: "phone", title: "Phone", value: phone)
                }
                if let location = appState.profile.location, !location.isEmpty {
                    infoRow(icon: "mappin.and.ellipse", title: "Location", value: location)
                }
                if let dob = appState.profile.dateOfBirth {
                    infoRow(icon: "gift",
                            title: "Date of Birth",
                            value: ProfileViewModel.dobFormatter.string(from: dob))
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.thinMaterial)
            )

            Section("Shared") {
                settingsRow(icon: "photo.on.rectangle.angled", tint: Color.accentColor, title: "Shared Media", destination: .sharedMedia)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.thinMaterial)
            )

            Section("Categories") {
                settingsRow(icon: "paintpalette", tint: Color.accentColor, title: "Appearance", destination: .appearance)
                settingsRow(icon: "bell.badge", tint: .red, title: "Notifications", destination: .notifications)
                settingsRow(icon: "lock.shield", tint: .green, title: "Privacy & Security", destination: .privacy)
                settingsRow(icon: "internalmemory", tint: .orange, title: "Data & Storage", destination: .dataStorage)
                settingsRow(icon: "folder", tint: .indigo, title: "Chat Folders", destination: .chatFolders)
                settingsRow(icon: "laptopcomputer.and.iphone", tint: .cyan, title: "Devices", destination: .devices)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.thinMaterial)
            )

            Section {
                Button(role: .destructive) {
                    confirmLogout = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(AppTypography.callout.weight(.semibold))
                        Spacer()
                    }
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.thinMaterial)
            )

            // Bottom clearance (V3 §8): Log Out must stay reachable and the
            // list must scroll fully clear of the floating tab bar.
            Section {
                Color.clear
                    .frame(height: 40)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityHidden(true)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .confirmationDialog("Log out of LiquidMessenger?",
                            isPresented: $confirmLogout,
                            titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                haptics.warning()
                router.resetNavigation()
                // Profile data is preserved; log back in with the same flow.
                isLoggedIn = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your profile and Saved messages stay on this device.")
        }
    }

    private var profileCard: some View {
        VStack(spacing: AppSpacing.md) {
            AvatarView(name: appState.profile.name,
                       gradientIndex: appState.profile.gradientIndex,
                       size: 92,
                       isOnline: appState.profile.isOnline)

            VStack(spacing: 3) {
                Text(appState.profile.name)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.primary)
                Text("@" + appState.profile.username)
                    .font(AppTypography.footnote)
                    .foregroundStyle(Color.accentColor)
                if !appState.profile.bio.isEmpty {
                    Text(appState.profile.bio)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }

            GlassButton(title: "Edit Profile", icon: "pencil") {
                haptics.selection()
                router.settingsPath.append(.editProfile)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
        .accessibilityElement(children: .combine)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    /// Category row. The native `NavigationLink` disclosure indicator is the
    /// ONLY chevron (V3 §9 — no manually drawn second chevron).
    private func settingsRow(icon: String, tint: Color, title: String, destination: SettingsDestination) -> some View {
        NavigationLink(value: destination) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous).fill(tint))
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
}
