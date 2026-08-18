import SwiftUI

/// Profile editor with live validation; changes apply immediately on Save.
struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ProfileViewModel(appState: AppContainer.appState)

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: AppSpacing.xs) {
                        AvatarView(name: vm.name.isEmpty ? "?" : vm.name,
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
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    TextField("Name", text: $vm.name)
                        .onChange(of: vm.name) { newValue in
                            if newValue.count > ProfileViewModel.nameMaxLength {
                                vm.name = String(newValue.prefix(ProfileViewModel.nameMaxLength))
                            }
                        }
                    if let error = vm.nameError, !vm.name.isEmpty {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.destructive)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    TextField("Username", text: $vm.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: vm.username) { _ in vm.sanitizeUsername() }
                    if let error = vm.usernameError, !vm.username.isEmpty {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.destructive)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    TextField("Bio", text: $vm.bio, axis: .vertical)
                        .lineLimit(3...5)
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
            } header: {
                Text("Profile")
            } footer: {
                Text("Username: 3–20 characters, lowercase letters, numbers and underscores only.")
            }
        }
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
}
