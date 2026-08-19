import SwiftUI

/// Auth entry screen: branding, subtitle and the primary CTA that opens
/// the phone-number flow.
struct WelcomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                logo
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: AppSpacing.xs) {
                    Text("LiquidMessenger")
                        .font(AppTypography.largeTitle.weight(.bold))
                        .foregroundStyle(AppColors.primary)
                    Text("Fast, private messaging with a liquid glass soul.")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 12)
            }

            Spacer()

            Button {
                haptics.impact(.light)
                router.isPhoneFlowPresented = true
            } label: {
                Text("Start Messaging")
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm + 2)
                    .background(
                        ZStack {
                            Capsule().fill(
                                LinearGradient(colors: [Color.accentColor,
                                                        Color.accentColor.opacity(0.72)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                        }
                    )
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(GlassPressStyle())
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 16)

            Text("Demo authentication · OTP 11111")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.tertiary)
                .padding(.top, AppSpacing.md)
                .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, AppSpacing.xxl)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard !reduceMotion else {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var logo: some View {
        ZStack {
            GlassBackground(style: GlassStyle(tint: .accentColor,
                                              tintOpacity: 0.18,
                                              cornerRadius: 32,
                                              strokeOpacity: 0.4,
                                              shadowRadius: 20))
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 46))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 112, height: 112)
        .accessibilityHidden(true)
    }
}
