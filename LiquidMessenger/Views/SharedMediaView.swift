import SwiftUI

/// Telegram-style Shared Media with Photos / Files / Links segments.
/// Content is derived exclusively from real local messages — each tab shows
/// a polished empty state instead of invented data (V3 §32–35).
struct SharedMediaView: View {
    @StateObject private var vm = SharedMediaViewModel(messageService: AppContainer.messageService)
    @State private var segment: Segment = .photos

    enum Segment: String, CaseIterable, Identifiable {
        case photos = "Photos"
        case files = "Files"
        case links = "Links"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $segment.animation(.easeOut(duration: 0.18))) {
                ForEach(Segment.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)

            switch segment {
            case .photos: photosTab
            case .files: filesTab
            case .links: linksTab
            }
        }
        .background(AppColors.background)
        .navigationTitle("Shared Media")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Photos

    private var photosTab: some View {
        Group {
            if vm.photos.isEmpty {
                emptyState(icon: "photo.on.rectangle",
                           title: "No photos yet",
                           subtitle: "Photos and videos you send or receive will appear here.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 2)], spacing: 2) {
                        ForEach(vm.photos) { message in
                            photoTile(message)
                        }
                    }
                    .padding(2)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Local attachments carry metadata only (no pixel data in this demo),
    /// so tiles render a deterministic gradient with the media name.
    private func photoTile(_ message: Message) -> some View {
        ZStack {
            AppColors.avatarGradient(abs(message.id.hashValue))
            VStack(spacing: 4) {
                Image(systemName: message.kind == .video ? "play.circle.fill" : "photo.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white.opacity(0.9))
                Text(message.attachment?.name ?? (message.kind == .video ? "Video" : "Photo"))
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.attachment?.name ?? "Media")
    }

    // MARK: Files

    private var filesTab: some View {
        Group {
            if vm.files.isEmpty {
                emptyState(icon: "doc",
                           title: "No files yet",
                           subtitle: "Documents shared in your conversations will be listed here.")
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(vm.files) { message in
                            fileRow(message)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func fileRow(_ message: Message) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "doc.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                    .fill(Color.accentColor.opacity(0.85)))
            VStack(alignment: .leading, spacing: 2) {
                Text(message.attachment?.name ?? "File")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)
                Text(message.date.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
            }
            Spacer()
        }
        .glassCard(padding: AppSpacing.sm)
        .accessibilityElement(children: .combine)
    }

    // MARK: Links

    private var linksTab: some View {
        Group {
            if vm.links.isEmpty {
                emptyState(icon: "link",
                           title: "No links yet",
                           subtitle: "Links from your messages will be collected here.")
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xs) {
                        ForEach(vm.links) { link in
                            linkRow(link)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func linkRow(_ link: SharedLink) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(link.url.host ?? link.url.absoluteString)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)
                Text(link.url.absoluteString)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .glassCard(padding: AppSpacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Link: \(link.url.absoluteString)")
    }

    // MARK: Empty state

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
            }
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.primary)
            Text(subtitle)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 280)
        .padding(AppSpacing.xl)
        .accessibilityElement(children: .combine)
    }
}
