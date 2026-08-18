import SwiftUI
import Combine

/// Polished composer: attachment menu, expanding text field, reply banner,
/// attachment preview, voice-record UI and a send/mic switch.
/// Keyboard safety comes from SwiftUI's automatic safe-area avoidance —
/// no hardcoded keyboard heights anywhere.
struct MessageInputBar: View {
    @Binding var text: String
    var replyTarget: Message?
    var pendingAttachment: MessageAttachment?
    var onSend: () -> Void
    var onCancelReply: () -> Void
    var onRemoveAttachment: () -> Void
    var onPickAttachment: (MessageKind) -> Void
    var onSendVoiceNote: (TimeInterval) -> Void

    @State private var fieldHeight: CGFloat = 38
    @State private var isRecording = false
    @State private var recordingSeconds: Int = 0
    @FocusState private var isFocused: Bool

    @EnvironmentObject private var haptics: HapticService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingAttachment != nil
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            if let replyTarget {
                replyBanner(replyTarget)
            }
            if let pendingAttachment {
                attachmentPreview(pendingAttachment)
            }
            if isRecording {
                recordingBar
            } else {
                inputRow
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(
            GlassBackground(style: GlassStyle(cornerRadius: AppRadius.extraLarge, shadowRadius: 10))
        )
        .padding(.horizontal, AppSpacing.xs)
        .onReceive(timer) { _ in
            if isRecording { recordingSeconds += 1 }
        }
    }

    // MARK: Main input row

    private var inputRow: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.xs) {
            Menu {
                Button { onPickAttachment(.image) } label: { Label("Photo", systemImage: "photo") }
                Button { onPickAttachment(.video) } label: { Label("Video", systemImage: "video") }
                Button { onPickAttachment(.file) } label: { Label("Document", systemImage: "doc") }
                Button { onPickAttachment(.location) } label: { Label("Location", systemImage: "location") }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 6)
            }
            .accessibilityLabel("Add attachment")

            ZStack(alignment: .leading) {
                // Hidden replica measures the natural height of the current text
                // so the field expands smoothly without GeometryReader in hot paths.
                Text(text.isEmpty ? " " : text)
                    .font(AppTypography.body)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 9)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { updateHeight(proxy.size.height) }
                                .onChange(of: proxy.size.height) { updateHeight($0) }
                        }
                    )
                    .opacity(0)
                    .accessibilityHidden(true)

                TextField("Message", text: $text, axis: .vertical)
                    .font(AppTypography.body)
                    .focused($isFocused)
                    .frame(height: fieldHeight)
                    .padding(.horizontal, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: fieldHeight / 2, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: fieldHeight / 2, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
                    )
                    .onSubmit {
                        if hasContent { send() }
                    }
            }

            if hasContent {
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color.accentColor)
                }
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                .accessibilityLabel("Send message")
            } else {
                Button(action: startRecording) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.secondary)
                        .frame(width: 30, height: 30)
                }
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                .accessibilityLabel("Record voice message")
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: hasContent)
    }

    // MARK: Reply banner

    private func replyBanner(_ message: Message) -> some View {
        HStack(spacing: AppSpacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(message.incoming ? "Reply" : "Reply to yourself")
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Text(message.preview)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button(action: onCancelReply) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.tertiary)
            }
            .accessibilityLabel("Cancel reply")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).fill(.thinMaterial))
    }

    // MARK: Attachment preview

    private func attachmentPreview(_ attachment: MessageAttachment) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: attachmentIcon(attachment.kind))
                .font(.system(size: 18))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous).fill(Color.accentColor.opacity(0.14)))
            VStack(alignment: .leading, spacing: 1) {
                Text(attachment.name)
                    .font(AppTypography.footnote.weight(.medium))
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)
                Text(label(for: attachment))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
            Button(action: onRemoveAttachment) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.tertiary)
            }
            .accessibilityLabel("Remove attachment")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).fill(.thinMaterial))
    }

    private func attachmentIcon(_ kind: MessageKind) -> String {
        switch kind {
        case .image: return "photo"
        case .video: return "video"
        case .file: return "doc"
        case .location: return "mappin.and.ellipse"
        default: return "paperclip"
        }
    }

    private func label(for attachment: MessageAttachment) -> String {
        switch attachment.kind {
        case .image: return "Photo"
        case .video: return "Video"
        case .file: return "Document"
        case .location: return "Location"
        default: return "Attachment"
        }
    }

    // MARK: Recording

    private var recordingBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(Color.red)
                .frame(width: 9, height: 9)
                .opacity(recordingSeconds % 2 == 0 ? 1 : 0.35)

            Text(TimeFormatting.durationLabel(TimeInterval(recordingSeconds)))
                .font(AppTypography.callout.monospacedDigit())
                .foregroundStyle(AppColors.primary)

            Text("Recording voice message…")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.secondary)
                .lineLimit(1)

            Spacer()

            Button(action: cancelRecording) {
                Image(systemName: "trash")
                    .font(.system(size: 17))
                    .foregroundStyle(AppColors.destructive)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Discard voice message")

            Button(action: finishRecording) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("Send voice message")
        }
    }

    // MARK: Actions

    private func updateHeight(_ height: CGFloat) {
        let clamped = min(max(height, 38), 110)
        if abs(clamped - fieldHeight) > 1 {
            fieldHeight = clamped
        }
    }

    private func send() {
        haptics.impact(.light)
        onSend()
        text = ""
    }

    private func startRecording() {
        haptics.impact(.medium)
        recordingSeconds = 0
        isRecording = true
    }

    private func finishRecording() {
        haptics.success()
        isRecording = false
        onSendVoiceNote(TimeInterval(recordingSeconds))
        recordingSeconds = 0
    }

    private func cancelRecording() {
        haptics.warning()
        isRecording = false
        recordingSeconds = 0
    }
}
