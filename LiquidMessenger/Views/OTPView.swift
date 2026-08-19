import SwiftUI
import Combine

/// Demo OTP screen: the code is `11111`. Entering it authenticates
/// immediately, persists the phone number into the profile and flips
/// `isLoggedIn` — no backend, no artificial delays.
struct OTPView: View {
    let fullPhoneNumber: String

    @AppStorage(AppStorageKeys.isLoggedIn) private var isLoggedIn = false
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var code = ""
    @State private var resendSeconds = 30
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isFocused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private static let demoCode = "11111"
    private static let codeLength = 5

    private var maskedNumber: String {
        let digits = fullPhoneNumber.filter(\.isNumber)
        guard digits.count > 4 else { return fullPhoneNumber }
        return "+" + String(digits.prefix(digits.count - 2)) + " •• " + String(digits.suffix(2))
    }

    private var digits: [String] {
        var result = code.map(String.init)
        while result.count < Self.codeLength {
            result.append("")
        }
        return result
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 92, height: 92)
                    .background(
                        GlassBackground(style: GlassStyle(tint: .accentColor,
                                                          tintOpacity: 0.15,
                                                          cornerRadius: 28,
                                                          strokeOpacity: 0.35,
                                                          shadowRadius: 14))
                    )
                    .accessibilityHidden(true)

                Text("Enter Code")
                    .font(AppTypography.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.primary)

                Text("We sent a demo code to\n\(maskedNumber)")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)
            }

            codeBoxes
                .offset(x: shakeOffset)

            resendRow

            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.bottom, AppSpacing.xxl)
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = true }
        .onReceive(timer) { _ in
            if resendSeconds > 0 { resendSeconds -= 1 }
        }
    }

    // MARK: Code boxes

    private var codeBoxes: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(0..<Self.codeLength, id: \.self) { index in
                Text(digits[index])
                    .font(AppTypography.title.monospacedDigit())
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 48, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .fill(.thinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .strokeBorder(index == code.count && isFocused
                                          ? Color.accentColor.opacity(0.7)
                                          : Color.white.opacity(0.18),
                                          lineWidth: 1)
                    )
            }
        }
        // Invisible capturing field drives the keyboard.
        .overlay(
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityLabel("Verification code")
        )
        .onChange(of: code) { newValue in
            let sanitized = String(newValue.filter(\.isNumber).prefix(Self.codeLength))
            if sanitized != newValue {
                code = sanitized
                return
            }
            if sanitized.count == Self.codeLength {
                verify(sanitized)
            }
        }
    }

    // MARK: Resend row

    private var resendRow: some View {
        Group {
            if resendSeconds > 0 {
                Text("Resend code in 0:\(String(format: "%02d", resendSeconds))")
                    .font(AppTypography.footnote.monospacedDigit())
                    .foregroundStyle(AppColors.tertiary)
            } else {
                Button {
                    resendSeconds = 30
                    haptics.selection()
                } label: {
                    Text("Resend code")
                        .font(AppTypography.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityLabel(resendSeconds > 0
                            ? "Resend code available in \(resendSeconds) seconds"
                            : "Resend code")
    }

    // MARK: Verification

    private func verify(_ entered: String) {
        if entered == Self.demoCode {
            haptics.success()
            // Persist the real phone number from the auth flow.
            var profile = appState.profile
            profile.phoneNumber = fullPhoneNumber
            appState.profile = profile
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                isLoggedIn = true
            }
        } else {
            haptics.error()
            shake {
                code = ""
            }
        }
    }

    private func shake(reset: @escaping () -> Void) {
        guard !reduceMotion else {
            reset()
            return
        }
        let amplitude: CGFloat = 9
        withAnimation(.linear(duration: 0.06)) { shakeOffset = -amplitude }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.linear(duration: 0.06)) { shakeOffset = amplitude }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.linear(duration: 0.06)) { shakeOffset = -amplitude / 2 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.linear(duration: 0.06)) { shakeOffset = 0 }
            reset()
        }
    }
}
