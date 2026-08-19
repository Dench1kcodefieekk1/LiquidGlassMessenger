import SwiftUI

/// Profile editor with live validation; changes apply immediately on Save.
///
/// V3 keyboard handling: the whole screen is a `ScrollView` with interactive
/// scroll-to-dismiss, so every field (Username, Bio, Location, Date of Birth)
/// stays reachable while the keyboard is up — no hardcoded keyboard heights.
struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ProfileViewModel(appState: AppContainer.appState)

    /// Clearance so the last controls never sit under the floating tab bar.
    /// The tab bar already insets the safe area; this adds breathing room.
    private let bottomClearance: CGFloat = 110

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                avatarSection
                profileSection
                detailsSection
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, bottomClearance)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if vm.save() {
                        haptics.success()
                        dismiss()
                    } else {
                        haptics.error()
                    }
                }
                .disabled(!vm.isValid)
            }
        }
    }

    // MARK: Sections

    private var avatarSection: some View {
        VStack(spacing: AppSpacing.xs) {
            AvatarView(name: vm.displayName.isEmpty ? "?" : vm.displayName,
                       gradientIndex: appState.profile.gradientIndex,
                       size: 84)
            Button("Change Avatar") {
                // Cycle the gradient to simulate picking a new avatar.
                var profile = appState.profile
                profile.gradientIndex = (profile.gradientIndex + 1) % 10
                appState.profile = profile
                haptics.selection()
            }
            .font(AppTypography.footnote.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .contain)
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Profile")

            fieldCell {
                GlassTextField(placeholder: "First Name", text: $vm.firstName)
                    .onChange(of: vm.firstName) { newValue in
                        if newValue.count > ProfileViewModel.nameMaxLength {
                            vm.firstName = String(newValue.prefix(ProfileViewModel.nameMaxLength))
                        }
                    }
            } error: {
                vm.firstName.isEmpty ? nil : vm.firstNameError
            }

            fieldCell {
                GlassTextField(placeholder: "Last Name", text: $vm.lastName)
                    .onChange(of: vm.lastName) { newValue in
                        if newValue.count > ProfileViewModel.nameMaxLength {
                            vm.lastName = String(newValue.prefix(ProfileViewModel.nameMaxLength))
                        }
                    }
            } error: {
                vm.lastName.isEmpty ? nil : vm.lastNameError
            }

            fieldCell {
                GlassTextField(placeholder: "Username", text: $vm.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: vm.username) { _ in vm.sanitizeUsername() }
            } error: {
                vm.username.isEmpty ? nil : vm.usernameError
            } footer: {
                "Username: 3–20 characters, lowercase letters, numbers and underscores only."
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                GlassTextField(placeholder: "Bio", text: $vm.bio)
                    .onChange(of: vm.bio) { newValue in
                        if newValue.count > ProfileViewModel.bioMaxLength {
                            vm.bio = String(newValue.prefix(ProfileViewModel.bioMaxLength))
                        }
                    }
                HStack {
                    Spacer()
                    Text("\(vm.bioRemaining)")
                        .font(AppTypography.caption.monospacedDigit())
                        .foregroundStyle(vm.bioRemaining < 20 ? AppColors.destructive : AppColors.secondary)
                }
            }
        }
        .glassCard()
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Details")

            fieldCell {
                GlassTextField(placeholder: "Phone", text: $vm.phoneNumber)
                    .keyboardType(.phonePad)
            } error: {
                vm.phoneError
            }

            fieldCell {
                GlassTextField(placeholder: "Location", text: $vm.location)
                    .onChange(of: vm.location) { newValue in
                        if newValue.count > ProfileViewModel.locationMaxLength {
                            vm.location = String(newValue.prefix(ProfileViewModel.locationMaxLength))
                        }
                    }
            } error: { nil }

            Toggle("Date of Birth", isOn: $vm.dobEnabled.animation())
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primary)
            if vm.dobEnabled {
                DatePicker("Born", selection: $vm.dateOfBirth,
                           in: ...Date(),
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .foregroundStyle(AppColors.primary)
                    .transition(.opacity)
            }
        }
        .glassCard()
    }

    // MARK: Building blocks

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(AppColors.secondary)
    }

    /// Field + validation error + optional footer hint.
    private func fieldCell<Content: View>(
        @ViewBuilder content: () -> Content,
        error: () -> String?,
        footer: () -> String? = { nil }
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            content()
            if let message = error() {
                Text(message)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.destructive)
            }
            if let hint = footer() {
                Text(hint)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }
        }
    }
}
