import SwiftUI

/// Gradient-initials avatar. Sizes follow a fixed frame so list rows stay cheap.
struct AvatarView: View {
    let name: String
    let gradientIndex: Int
    var size: CGFloat = 52
    var isOnline: Bool = false

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(AppColors.avatarGradient(gradientIndex))
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))

            if isOnline {
                OnlineIndicator(size: size * 0.26)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Green presence dot with a border matching the surrounding surface.
struct OnlineIndicator: View {
    var size: CGFloat = 14

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(AppColors.background, lineWidth: 2))
            .accessibilityLabel("Online")
    }
}
