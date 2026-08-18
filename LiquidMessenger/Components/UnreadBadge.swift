import SwiftUI

/// Unread-count pill used in chat rows.
struct UnreadBadge: View {
    let count: Int
    var isMuted: Bool = false

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(AppTypography.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .frame(minWidth: 22)
            .background(Capsule().fill(isMuted ? Color.gray.opacity(0.55) : Color.accentColor))
            .accessibilityLabel("\(count) unread messages")
    }
}

/// Delivery/read receipt glyph for outgoing messages.
struct StatusIcon: View {
    let status: MessageStatus
    var tint: Color = .white.opacity(0.9)

    var body: some View {
        Group {
            switch status {
            case .sending:
                Image(systemName: "clock")
            case .sent:
                Image(systemName: "checkmark")
            case .delivered:
                Image(systemName: "checkmark")
            case .read:
                Image(systemName: "checkmark")
            case .failed:
                Image(systemName: "exclamationmark.circle")
            }
        }
        .font(.system(size: 11, weight: .semibold))
        .overlay(alignment: .topTrailing) {
            if status == .read {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .offset(x: 3.5, y: 0.5)
            }
        }
        .foregroundStyle(status == .failed ? Color.red : tint)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch status {
        case .sending: return "Sending"
        case .sent: return "Sent"
        case .delivered: return "Delivered"
        case .read: return "Read"
        case .failed: return "Failed to send"
        }
    }
}
