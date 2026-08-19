import SwiftUI

/// A chat folder. Built-in folders are fixed; custom folders are created by
/// the user and persisted locally (V3 §41 — no sync claims).
struct ChatFolder: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var name: String
    var isBuiltIn: Bool

    init(id: String = UUID().uuidString, name: String, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
    }
}

/// Telegram-style Chat Folders screen. Everything is stored on-device;
/// the selection survives restarts via `@AppStorage`.
struct ChatFoldersView: View {
    @AppStorage(AppStorageKeys.selectedChatFolder) private var selectedFolderID = ChatFoldersView.allChatsID
    @EnvironmentObject private var haptics: HapticService
    @State private var customFolders: [ChatFolder] =
        PersistenceService.load([ChatFolder].self, key: PersistenceKeys.chatFolders) ?? []
    @State private var newFolderName = ""
    @FocusState private var isNameFieldFocused: Bool

    static let allChatsID = "folder.all"

    private static let builtInFolders: [ChatFolder] = [
        ChatFolder(id: allChatsID, name: "All Chats", isBuiltIn: true),
        ChatFolder(id: "folder.personal", name: "Personal", isBuiltIn: true),
        ChatFolder(id: "folder.work", name: "Work", isBuiltIn: true)
    ]

    private static let nameMaxLength = 24

    var body: some View {
        List {
            Section {
                ForEach(Self.builtInFolders + customFolders) { folder in
                    folderRow(folder)
                }
            } header: {
                Text("Folders")
            } footer: {
                Text("Folders organize your chat list and are stored on this device only.")
            }

            Section("New Folder") {
                HStack(spacing: AppSpacing.sm) {
                    TextField("Folder name", text: $newFolderName)
                        .focused($isNameFieldFocused)
                        .onChange(of: newFolderName) { newValue in
                            if newValue.count > Self.nameMaxLength {
                                newFolderName = String(newValue.prefix(Self.nameMaxLength))
                            }
                        }
                        .submitLabel(.done)
                        .onSubmit(addFolder)
                    Button(action: addFolder) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(canAdd ? Color.accentColor : AppColors.tertiary)
                    }
                    .disabled(!canAdd)
                    .accessibilityLabel("Add folder")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Chat Folders")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Guard against a persisted selection pointing at a removed folder.
            if !allFolders.contains(where: { $0.id == selectedFolderID }) {
                selectedFolderID = Self.allChatsID
            }
        }
    }

    private var allFolders: [ChatFolder] { Self.builtInFolders + customFolders }

    private var canAdd: Bool {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !allFolders.contains { $0.name.lowercased() == trimmed.lowercased() }
    }

    private func addFolder() {
        guard canAdd else { return }
        let folder = ChatFolder(name: newFolderName.trimmingCharacters(in: .whitespaces))
        customFolders.append(folder)
        persist()
        newFolderName = ""
        isNameFieldFocused = false
        haptics.success()
    }

    private func remove(_ folder: ChatFolder) {
        customFolders.removeAll { $0.id == folder.id }
        if selectedFolderID == folder.id {
            selectedFolderID = Self.allChatsID
        }
        persist()
        haptics.impact(.light)
    }

    private func persist() {
        PersistenceService.save(customFolders, key: PersistenceKeys.chatFolders)
    }

    private func folderRow(_ folder: ChatFolder) -> some View {
        Button {
            guard selectedFolderID != folder.id else { return }
            selectedFolderID = folder.id
            haptics.selection()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: folder.isBuiltIn ? "folder.fill" : "folder")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 26)
                Text(folder.name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.primary)
                Spacer()
                if selectedFolderID == folder.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(selectedFolderID == folder.id ? [.isSelected] : [])
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !folder.isBuiltIn {
                Button(role: .destructive) {
                    remove(folder)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
