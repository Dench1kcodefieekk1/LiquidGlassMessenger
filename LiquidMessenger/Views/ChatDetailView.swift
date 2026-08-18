import SwiftUI

/// Conversation screen: header with presence, message history with date
/// separators, typing indicator, reactions, replies and the composer.
struct ChatDetailView: View {
    let chatID: String

    @StateObject private var vm: ChatDetailViewModel
    @EnvironmentObject private var chatService: ChatService
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draftText = ""

    init(chatID: String) {
        self.chatID = chatID
        _vm = StateObject(wrappedValue: ChatDetailViewModel(
            chatID: chatID,
            messageService: AppContainer.messageService,
            chatService: AppContainer.chatService
        ))
    }

    private var chat: Chat? { chatService.chat(id: chatID) }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                messageList(maxWidth: geometry.size.width * 0.72)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MessageInputBar(text: $draftText,
                            replyTarget: vm.replyTarget,
                            pendingAttachment: vm.pendingAttachment,
                            onSend: {
                                vm.send(text: draftText)
                                draftText = ""
                            },
                            onCancelReply: { vm.cancelReply() },
                            onRemoveAttachment: { vm.pendingAttachment = nil },
                            onPickAttachment: { pickAttachment($0) },
                            onSendVoiceNote: { duration in
                                vm.sendVoiceNote(duration: duration)
                            })
                .padding(.bottom, AppSpacing.xxs)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Mock attachment creation (no network/camera access in the demo).
    private func pickAttachment(_ kind: MessageKind) {
        let attachment: MessageAttachment
        switch kind {
        case .image: attachment = .init(kind: .image, name: "IMG_2049.jpg")
        case .video: attachment = .init(kind: .video, name: "IMG_1187.MOV", duration: 34)
        case .file: attachment = .init(kind: .file, name: "Document.pdf")
        case .location: attachment = .init(kind: .location, name: "Current location")
        default: return
        }
        vm.pendingAttachment = attachment
        haptics.selection()
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("Back")

            if let chat {
                AvatarView(name: chat.peer.name,
                           gradientIndex: chat.peer.gradientIndex,
                           size: 38,
                           isOnline: chat.peer.isOnline)

                VStack(alignment: .leading, spacing: 1) {
                    Text(chat.peer.name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primary)
                        .lineLimit(1)
                    statusLabel(for: chat)
                }
            }

            Spacer()

            Button {
                haptics.impact(.light)
            } label: {
                Image(systemName: "phone")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("Start audio call")

            Button {
                haptics.impact(.light)
            } label: {
                Image(systemName: "video")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("Start video call")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial.opacity(0.01))
    }

    private func statusLabel(for chat: Chat) -> some View {
        Group {
            if chat.isTyping {
                Text("typing…")
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(TimeFormatting.lastSeenLabel(for: chat.peer))
                    .foregroundStyle(chat.peer.isOnline ? Color.green : AppColors.secondary)
            }
        }
        .font(AppTypography.caption)
    }

    // MARK: Message list

    private func messageList(maxWidth: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.xs) {
                    ForEach(vm.displayItems) { item in
                        switch item {
                        case .separator(_, let label):
                            dateSeparator(label)
                        case .message(let message):
                            MessageBubble(message: message,
                                          maxWidth: maxWidth,
                                          onReply: { target in
                                              haptics.selection()
                                              vm.setReply(target)
                                          },
                                          onReact: { emoji, target in
                                              haptics.impact(.light)
                                              vm.toggleReaction(emoji, on: target)
                                          },
                                          onDelete: { target in
                                              haptics.warning()
                                              vm.delete(target)
                                          })
                        }
                    }

                    if chat?.isTyping == true {
                        HStack {
                            TypingIndicatorBubble()
                            Spacer()
                        }
                        .padding(.leading, AppSpacing.xs)
                        .transition(.opacity)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("chat.bottom")
                }
                .padding(.horizontal, AppSpacing.xs)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.xxs)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                proxy.scrollTo("chat.bottom", anchor: .bottom)
            }
            .onChange(of: vm.messages.count) { _ in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    proxy.scrollTo("chat.bottom", anchor: .bottom)
                }
            }
        }
    }

    private func dateSeparator(_ label: String) -> some View {
        Text(label)
            .font(AppTypography.caption.weight(.medium))
            .foregroundStyle(AppColors.secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(Capsule().fill(.thinMaterial))
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxs)
            .accessibilityLabel("Date: \(label)")
    }
}
