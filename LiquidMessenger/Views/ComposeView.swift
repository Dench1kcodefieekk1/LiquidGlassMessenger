import SwiftUI

/// New-message sheet: pick a contact to start a conversation with.
struct ComposeView: View {
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var chatService: ChatService
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredContacts: [Contact] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return contactService.contacts }
        let lowered = trimmed.lowercased()
        return contactService.contacts.filter {
            $0.user.name.lowercased().contains(lowered)
                || $0.user.username.lowercased().contains(lowered)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredContacts) { contact in
                Button {
                    open(contact)
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        AvatarView(name: contact.user.name,
                                   gradientIndex: contact.user.gradientIndex,
                                   size: 44,
                                   isOnline: contact.user.isOnline)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(contact.user.name)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.primary)
                            Text("@" + contact.user.username)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens a chat with \(contact.user.name)")
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search contacts")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func open(_ contact: Contact) {
        haptics.impact(.light)
        let chatID = contactService.openChat(for: contact, using: chatService)
        dismiss()
        router.openChat(id: chatID)
    }
}
