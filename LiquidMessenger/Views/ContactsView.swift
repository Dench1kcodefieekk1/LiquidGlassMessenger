import SwiftUI

/// Alphabetical contact book with search, add and invite actions.
struct ContactsView: View {
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var chatService: ChatService
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var haptics: HapticService
    @State private var searchText = ""
    @State private var isAddContactPresented = false

    private var filteredContacts: [Contact] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return contactService.contacts }
        let lowered = trimmed.lowercased()
        return contactService.contacts.filter {
            $0.user.name.lowercased().contains(lowered)
                || $0.user.username.lowercased().contains(lowered)
        }
    }

    private struct ContactGroup: Identifiable {
        let letter: String
        let contacts: [Contact]
        var id: String { letter }
    }

    private var grouped: [ContactGroup] {
        let sorted = filteredContacts.sorted { $0.user.name < $1.user.name }
        let groupedByLetter = Dictionary(grouping: sorted) { contact in
            String(contact.user.name.prefix(1)).uppercased()
        }
        return groupedByLetter
            .map { ContactGroup(letter: $0.key, contacts: $0.value) }
            .sorted { $0.letter < $1.letter }
    }

    var body: some View {
        List {
            Section {
                Button {
                    haptics.selection()
                    isAddContactPresented = true
                } label: {
                    Label {
                        Text("Add Contact")
                            .foregroundStyle(AppColors.primary)
                    } icon: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Button {
                    haptics.selection()
                } label: {
                    Label {
                        Text("Invite Friends")
                            .foregroundStyle(AppColors.primary)
                    } icon: {
                        Image(systemName: "paperplane")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .fill(.thinMaterial)
            )

            ForEach(grouped) { group in
                Section(group.letter) {
                    ForEach(group.contacts) { contact in
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
                                    Text(contact.phoneNumber.isEmpty ? "@" + contact.user.username : contact.phoneNumber)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.secondary)
                                }
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens a chat with \(contact.user.name)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search contacts")
        .navigationTitle("Contacts")
        .sheet(isPresented: $isAddContactPresented) {
            AddContactSheet()
        }
    }

    private func open(_ contact: Contact) {
        haptics.impact(.light)
        let chatID = contactService.openChat(for: contact, using: chatService)
        router.openChat(id: chatID)
    }
}

/// Add-contact form with basic validation.
struct AddContactSheet: View {
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Name", text: $name)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        contactService.addContact(name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                                  phoneNumber: phone,
                                                  gradientIndex: Int.random(in: 0..<10))
                        haptics.success()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
