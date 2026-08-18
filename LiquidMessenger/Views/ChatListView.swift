import SwiftUI

/// Main conversation list with search, pinned section, swipe actions
/// and archive access.
struct ChatListView: View {
    @EnvironmentObject private var chatService: ChatService
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @StateObject private var vm = ChatListViewModel(chatService: AppContainer.chatService)

    var body: some View {
        ZStack {
            List {
                if vm.showArchived {
                    archiveHeader
                } else if vm.archivedCount > 0 {
                    archivedRow
                }

                if !vm.pinnedChats.isEmpty {
                    Section {
                        ForEach(vm.pinnedChats) { chat in
                            row(chat)
                        }
                    } header: {
                        sectionLabel("Pinned")
                    }
                }

                Section {
                    ForEach(vm.regularChats) { chat in
                        row(chat)
                    }
                } header: {
                    if !vm.pinnedChats.isEmpty {
                        sectionLabel("All chats")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            if vm.visibleChats.isEmpty {
                emptyState
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .toolbar(.hidden, for: .navigationBar)
        .animation(.default, value: vm.showArchived)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text(vm.showArchived ? "Archived" : "Chats")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.primary)

                Spacer()

                Button {
                    haptics.selection()
                    router.selectedTab = .settings
                } label: {
                    AvatarView(name: appState.profile.name,
                               gradientIndex: appState.profile.gradientIndex,
                               size: 36)
                }
                .accessibilityLabel("Open profile and settings")
            }
            .padding(.horizontal, AppSpacing.md)

            searchField
                .padding(.horizontal, AppSpacing.md)
        }
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.xs)
        .background(.ultraThinMaterial.opacity(0.01))
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.secondary)
            TextField("Search", text: Binding(
                get: { vm.searchText },
                set: { vm.searchTextChanged($0) }
            ))
            .font(AppTypography.callout)
            .autocorrectionDisabled()
            .accessibilityLabel("Search chats")
            if !vm.searchText.isEmpty {
                Button {
                    vm.searchTextChanged("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.tertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(.thinMaterial)
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.footnote.weight(.semibold))
            .foregroundStyle(AppColors.secondary)
            .textCase(nil)
            .padding(.leading, AppSpacing.md)
    }

    // MARK: Rows

    private func row(_ chat: Chat) -> some View {
        NavigationLink(value: chat.id) {
            ChatRow(chat: chat)
        }
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(AppColors.separator.opacity(0.5))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                haptics.impact(.medium)
                vm.delete(chat)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            Button {
                haptics.impact(.light)
                vm.toggleArchived(chat)
            } label: {
                Label(chat.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
            }
            .tint(.indigo)
        }
        .swipeActions(edge: .leading) {
            Button {
                haptics.impact(.light)
                vm.togglePinned(chat)
            } label: {
                Label(chat.isPinned ? "Unpin" : "Pin",
                      systemImage: chat.isPinned ? "pin.slash" : "pin")
            }
            .tint(Color.accentColor)

            Button {
                haptics.impact(.light)
                vm.toggleMuted(chat)
            } label: {
                Label(chat.isMuted ? "Unmute" : "Mute",
                      systemImage: chat.isMuted ? "speaker.wave.2" : "speaker.slash")
            }
            .tint(.gray)
        }
        .simultaneousGesture(TapGesture().onEnded {
            haptics.selection()
        })
    }

    private var archivedRow: some View {
        Button {
            haptics.selection()
            vm.showArchived = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.accentColor.opacity(0.14)))
                Text("Archived")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primary)
                Spacer()
                Text("\(vm.archivedCount)")
                    .font(AppTypography.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.secondary)
            }
            .padding(.vertical, AppSpacing.xxs)
        }
        .listRowBackground(Color.clear)
    }

    private var archiveHeader: some View {
        Button {
            haptics.selection()
            vm.showArchived = false
        } label: {
            HStack(spacing: AppSpacing.xxs) {
                Image(systemName: "chevron.left")
                Text("Back to chats")
            }
            .font(AppTypography.footnote.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }
        .listRowBackground(Color.clear)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.tertiary)
            Text(vm.showArchived ? "No archived chats" : "No chats found")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.secondary)
        }
    }
}
