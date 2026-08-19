import SwiftUI

/// Send-animation state machine (V2 §17): the composer text detaches,
/// flies upward and settles into the chat history as a real bubble.
enum MessageSendAnimationState: Equatable {
    case idle
    case preparing
    case morphing
    case completed
}

/// Conversation screen: header with presence, message history with date
/// separators, typing indicator, reactions, replies, the composer and the
/// fluid morphing send animation.
struct ChatDetailView: View {
    let chatID: String

    @StateObject private var vm: ChatDetailViewModel
    @EnvironmentObject private var chatService: ChatService
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draftText = ""

    // MARK: Morphing send state

    @State private var sendPhase: MessageSendAnimationState = .idle
    @State private var ghostMessage: Message?
    @State private var ghostSettled = false
    @State private var inputOriginY: CGFloat = 0
    @State private var lastMessageID: String?

    private var isSavedMessages: Bool { chatID == Chat.savedMessagesID }
    private var chat: Chat? { chatService.chat(id: chatID) }

    init(chatID: String) {
        self.chatID = chatID
        _vm = StateObject(wrappedValue: ChatDetailViewModel(
            chatID: chatID,
            messageService: AppContainer.messageService,
            chatService: AppContainer.chatService
        ))
    }

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
                            onSend: { sendText() },
                            onCancelReply: { vm.cancelReply() },
                            onRemoveAttachment: { vm.pendingAttachment = nil },
                            onPickAttachment: { pickAttachment($0) },
                            onSendVoiceNote: { duration in
                                vm.sendVoiceNote(duration: duration)
                            })
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: InputOriginKey.self,
                                               value: proxy.frame(in: .global).minY)
                    }
                )
                .padding(.bottom, AppSpacing.xxs)
        }
        .onPreferenceChange(InputOriginKey.self) { inputOriginY = $0 }
        .overlay {
            if sendPhase == .preparing || sendPhase == .morphing, let ghost = ghostMessage {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    morphGhost(ghost, maxWidth: width * 0.72)
                        .frame(width: width, height: proxy.size.height, alignment: .bottomTrailing)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
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

    // MARK: Morphing send

    private func sendText() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, sendPhase == .idle || sendPhase == .completed else {
            // Attachments / busy state fall back to the plain send path.
            if draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                vm.send(text: draftText)
            }
            return
        }
        // Clear the field first; the captured text keeps living in the ghost.
        draftText = ""
        if reduceMotion {
            vm.send(text: trimmed)
            return
        }
        morphSend(trimmed)
    }

    private func morphSend(_ text: String) {
        let message = Message(senderID: MockData.meID,
                              incoming: false,
                              kind: .text,
                              text: text,
                              date: Date(),
                              status: .sending,
                              replyToID: vm.replyTarget?.id,
                              replyPreview: vm.replyTarget?.preview)

        // preparing: the ghost spawns exactly where the input text was.
        sendPhase = .preparing
        ghostMessage = message
        ghostSettled = false

        DispatchQueue.main.async {
            // morphing: the real message is inserted (hidden) and the ghost
            // flies toward the bottom of the conversation.
            sendPhase = .morphing
            vm.send(text: text)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                ghostSettled = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                scrollToBottom(animated: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                // completed: swap ghost → real bubble in a single frame.
                withAnimation(.easeOut(duration: 0.12)) {
                    ghostMessage = nil
                    sendPhase = .completed
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    sendPhase = .idle
                }
            }
        }
    }

    private func morphGhost(_ message: Message, maxWidth: CGFloat) -> some View {
        Text(message.text)
            .font(AppTypography.bubbleText)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous)
                .fill(AppColors.outgoingBubble))
            .frame(maxWidth: maxWidth, alignment: .trailing)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.xs)
            // Preparing: sit at the input field. Morphing: settle at the bottom.
            .offset(y: ghostSettled ? -AppSpacing.xl : max(inputOriginY - 128, 0))
            .scaleEffect(ghostSettled ? 1 : 0.94, anchor: .bottomTrailing)
            .opacity(sendPhase == .idle ? 0 : 1)
    }

    private func scrollToBottom(animated: Bool) {
        // Delegated to the list's own reader; kept as a helper for clarity.
        NotificationCenter.default.post(name: ChatDetailView.scrollToBottomNotification,
                                        object: nil,
                                        userInfo: ["animated": animated])
    }

    static let scrollToBottomNotification = Notification.Name("ChatDetailView.scrollToBottom")

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
                if isSavedMessages {
                    AvatarView(name: appState.profile.name,
                               gradientIndex: appState.profile.gradientIndex,
                               size: 38)
                } else {
                    AvatarView(name: chat.peer.name,
                               gradientIndex: chat.peer.gradientIndex,
                               size: 38,
                               isOnline: chat.peer.isOnline)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(chat.peer.name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primary)
                        .lineLimit(1)
                    statusLabel(for: chat)
                }
            }

            Spacer()

            if !isSavedMessages {
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
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(.ultraThinMaterial.opacity(0.01))
    }

    private func statusLabel(for chat: Chat) -> some View {
        Group {
            if isSavedMessages {
                Text("Your personal notes")
                    .foregroundStyle(Color.accentColor)
            } else if chat.isTyping {
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
                            if message.id == ghostMessage?.id && sendPhase != .completed && sendPhase != .idle {
                                // Real bubble exists but stays invisible while
                                // the ghost performs the morph.
                                MessageBubble(message: message, maxWidth: maxWidth)
                                    .hidden()
                            } else {
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
            .overlay {
                if vm.messages.isEmpty && sendPhase == .idle {
                    savedMessagesEmptyState
                }
            }
            .onAppear {
                proxy.scrollTo("chat.bottom", anchor: .bottom)
            }
            .onChange(of: vm.messages.last?.id) { newValue in
                lastMessageID = newValue
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                    proxy.scrollTo("chat.bottom", anchor: .bottom)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Self.scrollToBottomNotification)) { _ in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                    proxy.scrollTo("chat.bottom", anchor: .bottom)
                }
            }
        }
    }

    /// Polished empty state for the pristine self-chat (V2 §13).
    private var savedMessagesEmptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.16))
                    .frame(width: 74, height: 74)
                Image(systemName: isSavedMessages ? "bookmark.fill" : "bubble.left.and.bubble.right")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
            }
            Text(isSavedMessages ? "Saved Messages" : "No messages yet")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.primary)
            Text(isSavedMessages
                 ? "Save messages, links and notes here — they stay on your device."
                 : "Say hi to start the conversation.")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 300)
        .glassCard(style: .prominent)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
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

/// Preference key carrying the composer's global top edge, used as the
/// morph animation's start position (never hardcoded).
private struct InputOriginKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
