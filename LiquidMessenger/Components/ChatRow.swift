import SwiftUI

/// A single conversation row in the chat list.
/// Fixed avatar size and single-pass layout keep rows cheap for lazy lists.
struct ChatRow: View {
    let chat: Chat

    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            avatar

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(chat.peer.name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.primary)
                        .lineLimit(1)

                    if chat.isMuted {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.tertiary)
                    }
                    Spacer(minLength: 0)

                    if let lastMessage = chat.lastMessage {
                        Text(TimeFormatting.relativeDayLabel(for: lastMessage.date))
                            .font(AppTypography.timestamp)
                            .foregroundStyle(chat.unreadCount > 0 ? Color.accentColor : AppColors.secondary)
                    }
                }

                HStack(spacing: AppSpacing.xxs) {
                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.tertiary)
                    }

                    previewLine

                    Spacer(minLength: 0)

                    if chat.isTyping {
                        Text("typing…")
                            .font(AppTypography.footnote.italic())
                            .foregroundStyle(Color.accentColor)
                    } else if chat.unreadCount > 0 {
                        UnreadBadge(count: chat.unreadCount, isMuted: chat.isMuted)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    /// Saved Messages shows the user's own avatar with a bookmark badge.
    private var avatar: some View {
        Group {
            if chat.isSavedMessages {
                AvatarView(name: appState.profile.name,
                           gradientIndex: appState.profile.gradientIndex,
                           size: 52)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.accentColor))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8))
                    }
            } else {
                AvatarView(name: chat.peer.name,
                           gradientIndex: chat.peer.gradientIndex,
                           size: 52,
                           isOnline: chat.peer.isOnline)
            }
        }
    }

    @ViewBuilder
    private var previewLine: some View {
        if chat.isTyping {
            Text("typing…")
                .font(AppTypography.footnote.italic())
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
        } else if let lastMessage = chat.lastMessage {
            HStack(spacing: 3) {
                if !lastMessage.incoming {
                    StatusIcon(status: lastMessage.status, tint: AppColors.secondary)
                }
                if lastMessage.kind != .text, lastMessage.kind != .system {
                    Image(systemName: icon(for: lastMessage.kind))
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondary)
                }
                Text(lastMessage.preview)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.secondary)
                    .lineLimit(1)
            }
        } else {
            Text(chat.isSavedMessages ? "Save messages and notes here" : "No messages yet")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.tertiary)
        }
    }

    private func icon(for kind: MessageKind) -> String {
        switch kind {
        case .image: return "photo"
        case .video: return "video"
        case .file: return "doc"
        case .voice: return "mic"
        case .location: return "location"
        case .text, .system: return "text.bubble"
        }
    }

    private var accessibilitySummary: String {
        var parts = [chat.peer.name]
        if let lastMessage = chat.lastMessage {
            parts.append(lastMessage.preview)
        }
        if chat.unreadCount > 0 {
            parts.append("\(chat.unreadCount) unread")
        }
        if chat.isMuted { parts.append("muted") }
        if chat.isPinned { parts.append("pinned") }
        return parts.joined(separator: ", ")
    }
}
