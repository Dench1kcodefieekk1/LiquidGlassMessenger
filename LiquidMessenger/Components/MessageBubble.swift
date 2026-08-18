import SwiftUI

/// Message bubble supporting all content kinds, reactions, replies and
/// delivery states. `maxWidth` is provided by the parent (single measurement,
/// no GeometryReader per row).
struct MessageBubble: View {
    let message: Message
    var maxWidth: CGFloat = 260
    var onReply: (Message) -> Void = { _ in }
    var onReact: (String, Message) -> Void = { _, _ in }
    var onDelete: (Message) -> Void = { _ in }

    var body: some View {
        if message.kind == .system {
            systemBanner
        } else {
            HStack {
                if !message.incoming { Spacer(minLength: 48) }
                bubbleContent
                if message.incoming { Spacer(minLength: 48) }
            }
        }
    }

    // MARK: System message

    private var systemBanner: some View {
        Text(message.text)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xxs)
            .background(Capsule().fill(.thinMaterial))
            .frame(maxWidth: .infinity)
            .accessibilityLabel("System message: \(message.text)")
    }

    // MARK: Bubble

    private var bubbleContent: some View {
        VStack(alignment: message.incoming ? .leading : .trailing, spacing: AppSpacing.xxs) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if let replyPreview = message.replyPreview {
                    replyBanner(replyPreview)
                }
                contentBody
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .frame(maxWidth: maxWidth, alignment: message.incoming ? .leading : .trailing)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous))

            HStack(spacing: AppSpacing.xxs) {
                reactionsRow
                timestampRow
            }
        }
        .contextMenu {
            Button { onReply(message) } label: {
                Label("Reply", systemImage: "arrowshape.turn.up.left")
            }
            Button { onReact("❤️", message) } label: {
                Label("React", systemImage: "heart")
            }
            if message.kind == .text {
                Button {
                    UIPasteboard.general.string = message.text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            Button(role: .destructive) { onDelete(message) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.incoming {
            RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        } else {
            RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous)
                .fill(AppColors.outgoingBubble)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var contentBody: some View {
        switch message.kind {
        case .text:
            Text(message.text)
                .font(AppTypography.bubbleText)
                .foregroundStyle(message.incoming ? AppColors.primary : Color.white)
                .fixedSize(horizontal: false, vertical: true)

        case .image:
            attachmentPlaceholder(icon: "photo", title: message.attachment?.name ?? "Photo")

        case .video:
            attachmentPlaceholder(icon: "play.circle.fill",
                                  title: message.attachment?.name ?? "Video",
                                  subtitle: message.attachment?.duration.map(TimeFormatting.durationLabel))

        case .file:
            attachmentPlaceholder(icon: "doc.fill",
                                  title: message.attachment?.name ?? "File")

        case .voice:
            voiceContent

        case .location:
            locationContent

        case .system:
            EmptyView()
        }
    }

    private func attachmentPlaceholder(icon: String, title: String, subtitle: String? = nil) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill((message.incoming ? Color.accentColor : Color.white).opacity(message.incoming ? 0.15 : 0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(message.incoming ? Color.accentColor : Color.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.footnote.weight(.medium))
                    .foregroundStyle(message.incoming ? AppColors.primary : Color.white)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(message.incoming ? AppColors.secondary : Color.white.opacity(0.8))
                }
            }
            .frame(maxWidth: 180, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    private var voiceContent: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(message.incoming ? Color.accentColor : Color.white)

            // Static waveform
            HStack(spacing: 2.5) {
                ForEach(0..<14, id: \.self) { index in
                    Capsule()
                        .fill((message.incoming ? Color.accentColor : Color.white).opacity(0.75))
                        .frame(width: 3, height: waveHeight(index))
                }
            }

            VStack(alignment: .trailing, spacing: 1) {
                Text(TimeFormatting.durationLabel(message.attachment?.duration ?? 0))
                    .font(AppTypography.caption)
                    .foregroundStyle(message.incoming ? AppColors.secondary : Color.white.opacity(0.85))
            }
        }
        .padding(.vertical, AppSpacing.xxs)
        .accessibilityLabel("Voice message, \(TimeFormatting.durationLabel(message.attachment?.duration ?? 0))")
    }

    private func waveHeight(_ index: Int) -> CGFloat {
        let pattern: [CGFloat] = [8, 14, 10, 18, 12, 20, 9, 16, 11, 19, 8, 14, 10, 15]
        return pattern[index % pattern.count]
    }

    private var locationContent: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill((message.incoming ? Color.green.opacity(0.15) : Color.white.opacity(0.2)))
                    .frame(width: 44, height: 44)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                    .foregroundStyle(message.incoming ? Color.green : Color.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Location")
                    .font(AppTypography.footnote.weight(.semibold))
                    .foregroundStyle(message.incoming ? AppColors.primary : Color.white)
                Text(message.attachment?.name ?? "Shared location")
                    .font(AppTypography.caption)
                    .foregroundStyle(message.incoming ? AppColors.secondary : Color.white.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(maxWidth: 180, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    // MARK: Reply banner / reactions / timestamp

    private func replyBanner(_ preview: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(message.incoming ? Color.accentColor : Color.white.opacity(0.8))
                .frame(width: 3)
            Text(preview)
                .font(AppTypography.caption)
                .foregroundStyle(message.incoming ? AppColors.secondary : Color.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var reactionsRow: some View {
        HStack(spacing: 3) {
            ForEach(message.reactions.indices, id: \.self) { index in
                let reaction = message.reactions[index]
                HStack(spacing: 2) {
                    Text(reaction.emoji).font(.system(size: 11))
                    if reaction.count > 1 {
                        Text("\(reaction.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.secondary)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.thinMaterial)
                        .overlay(Capsule().strokeBorder(reaction.isFromMe ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1))
                )
                .onTapGesture { onReact(reaction.emoji, message) }
            }
        }
    }

    private var timestampRow: some View {
        HStack(spacing: 3) {
            Text(TimeFormatting.timeFormatter.string(from: message.date))
                .font(AppTypography.timestamp)
                .foregroundStyle(message.incoming ? AppColors.tertiary : Color.white.opacity(0.8))
            if !message.incoming {
                StatusIcon(status: message.status)
            }
        }
    }

    private var accessibilitySummary: String {
        var parts = [message.incoming ? "Received" : "Sent"]
        parts.append(message.preview)
        parts.append(TimeFormatting.timeFormatter.string(from: message.date))
        if !message.incoming { parts.append("status \(message.status.rawValue)") }
        return parts.joined(separator: ", ")
    }
}

/// Animated three-dot typing indicator bubble.
struct TypingIndicatorBubble: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColors.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(animating ? 0.9 : 0.3)
                    .animation(.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.18), value: animating)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.bubble, style: .continuous)
                .fill(.thinMaterial)
        )
        .onAppear { animating = true }
        .accessibilityLabel("Contact is typing")
    }
}
