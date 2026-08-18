import SwiftUI

/// Configuration for the layered glass surface.
struct GlassStyle {
    var tint: Color
    var tintOpacity: Double
    var cornerRadius: CGFloat
    var strokeOpacity: Double
    var shadowRadius: CGFloat

    init(tint: Color = .white,
         tintOpacity: Double = 0.06,
         cornerRadius: CGFloat = AppRadius.large,
         strokeOpacity: Double = 0.25,
         shadowRadius: CGFloat = 12) {
        self.tint = tint
        self.tintOpacity = tintOpacity
        self.cornerRadius = cornerRadius
        self.strokeOpacity = strokeOpacity
        self.shadowRadius = shadowRadius
    }

    static let standard = GlassStyle()
    static let prominent = GlassStyle(tintOpacity: 0.12, cornerRadius: AppRadius.extraLarge, strokeOpacity: 0.35, shadowRadius: 18)
    static let capsule = GlassStyle(cornerRadius: AppRadius.capsule, shadowRadius: 16)
}

/// Layered translucent surface: material base + tint gradient + specular stroke + soft shadow.
/// Built from iOS 16-safe primitives (materials, gradients, strokes) so it renders
/// consistently on every supported OS version.
struct GlassBackground: View {
    var style: GlassStyle = .standard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(colors: [style.tint.opacity(style.tintOpacity * 2),
                                            style.tint.opacity(style.tintOpacity * 0.4)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(style.strokeOpacity),
                                            Color.white.opacity(style.strokeOpacity * 0.15)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.10), radius: style.shadowRadius, x: 0, y: style.shadowRadius / 3)
    }
}

/// Wraps arbitrary content in a glass surface with padding.
struct GlassCard<Content: View>: View {
    var style: GlassStyle = .standard
    var padding: CGFloat = AppSpacing.md
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(GlassBackground(style: style))
    }
}

/// Glass button with press feedback.
struct GlassButton: View {
    let title: String
    var icon: String? = nil
    var style: GlassStyle = .standard
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.footnote.weight(.semibold))
                }
                Text(title)
                    .font(AppTypography.callout.weight(.semibold))
            }
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(GlassBackground(style: style))
        }
        .buttonStyle(GlassPressStyle())
        .accessibilityAddTraits(.isButton)
    }
}

/// Circular glass icon button.
struct GlassCircleButton: View {
    let icon: String
    var size: CGFloat = 44
    var tint: Color? = nil
    var style: GlassStyle = .capsule
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                GlassBackground(style: style)
                    .frame(width: size, height: size)
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(tint ?? AppColors.primary)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(GlassPressStyle())
    }
}

/// Small glass pill for counts/labels.
struct GlassBadge: View {
    let text: String
    var tint: Color = .accentColor

    var body: some View {
        Text(text)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8))
    }
}

/// Glass-styled text field.
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var cornerRadius: CGFloat = AppRadius.medium

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppTypography.body)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
    }
}

/// Glass sheet container used for custom overlays (attachment previews etc.).
struct GlassSheet<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            if let title {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primary)
            }
            content()
        }
        .padding(AppSpacing.lg)
        .background(GlassBackground(style: .prominent))
        .padding(AppSpacing.md)
    }
}

/// Shared press feedback for glass controls.
struct GlassPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View extensions

extension View {
    /// Applies a standard glass card surface.
    func glassCard(style: GlassStyle = .standard, padding: CGFloat = AppSpacing.md) -> some View {
        self
            .padding(padding)
            .background(GlassBackground(style: style))
    }

    /// Capsule glass chip surface.
    func glassChip(padding: CGFloat = AppSpacing.xs) -> some View {
        self
            .padding(.horizontal, padding + 4)
            .padding(.vertical, padding)
            .background(GlassBackground(style: .capsule))
    }
}
