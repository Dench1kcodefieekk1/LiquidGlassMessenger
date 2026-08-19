import SwiftUI

/// Phone-number authentication screen: country-code field with a live flag,
/// auto-focus handoff to the number field, validation and OTP navigation.
struct PhoneNumberView: View {
    @EnvironmentObject private var haptics: HapticService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var countryCode = "380"
    @State private var phoneNumber = ""
    @State private var isOTPPresented = false
    @FocusState private var focus: Field?

    private enum Field { case code, phone }

    /// Digits of the number, preformatted in 2-3-2-2 groups.
    private var formattedNumber: String {
        let digits = phoneNumber.filter(\.isNumber)
        var groups: [String] = []
        var index = digits.startIndex
        for size in [2, 3, 2, 2] where index < digits.endIndex {
            let end = digits.index(index, offsetBy: size, limitedBy: digits.endIndex) ?? digits.endIndex
            groups.append(String(digits[index..<end]))
            index = end
        }
        return groups.joined(separator: " ")
    }

    private var isMinimallyValid: Bool {
        let codeDigits = countryCode.filter(\.isNumber)
        let numberDigits = phoneNumber.filter(\.isNumber)
        return !codeDigits.isEmpty && numberDigits.count >= 6 && numberDigits.count <= 15
    }

    private var fullPhoneNumber: String {
        "+" + countryCode.filter(\.isNumber) + phoneNumber.filter(\.isNumber)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Text(CountryCodes.flag(forDigits: countryCode))
                    .font(.system(size: 64))
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7),
                               value: CountryCodes.flag(forDigits: countryCode))
                    .accessibilityHidden(true)

                Text("Your Phone")
                    .font(AppTypography.largeTitle.weight(.bold))
                    .foregroundStyle(AppColors.primary)

                Text("Please confirm your country code and enter your phone number.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            HStack(spacing: AppSpacing.xs) {
                codeField
                phoneField
            }
            .padding(.horizontal, AppSpacing.xl)

            Button(action: continueToOTP) {
                Text("Continue")
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm + 2)
                    .background(
                        Capsule().fill(isMinimallyValid
                                       ? Color.accentColor
                                       : Color.accentColor.opacity(0.35))
                    )
            }
            .buttonStyle(GlassPressStyle())
            .disabled(!isMinimallyValid)
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding(.bottom, AppSpacing.xxl)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isOTPPresented) {
            OTPView(fullPhoneNumber: fullPhoneNumber)
        }
        .onAppear {
            // Start on the number field: the default code is pre-filled.
            if phoneNumber.isEmpty {
                focus = .phone
            }
        }
    }

    // MARK: Fields

    private var codeField: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(CountryCodes.flag(forDigits: countryCode))
                .font(.system(size: 20))
            Text("+")
                .font(AppTypography.body.weight(.semibold))
                .foregroundStyle(AppColors.secondary)
            TextField("380", text: $countryCode)
                .font(AppTypography.body.weight(.semibold))
                .keyboardType(.numberPad)
                .focused($focus, equals: .code)
                .onChange(of: countryCode) { newValue in
                    handleCodeChange(newValue)
                }
                .frame(width: 44)
                .accessibilityLabel("Country code")
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).fill(.thinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(focus == .code ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.18),
                              lineWidth: 1)
        )
    }

    private var phoneField: some View {
        TextField("67 123 45 67", text: Binding(
            get: { formattedNumber },
            set: { newValue in
                phoneNumber = String(newValue.filter(\.isNumber).prefix(9))
            }
        ))
        .font(AppTypography.body)
        .keyboardType(.numberPad)
        .focused($focus, equals: .phone)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous).fill(.thinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(focus == .phone ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.18),
                              lineWidth: 1)
        )
        .accessibilityLabel("Phone number")
    }

    // MARK: Focus handoff

    private func handleCodeChange(_ newValue: String) {
        let digits = newValue.filter(\.isNumber)
        if digits != newValue {
            countryCode = digits
            return
        }
        if digits.count > CountryCodes.maxLength {
            countryCode = String(digits.prefix(CountryCodes.maxLength))
            return
        }
        // Exact recognized code → hand focus to the number field.
        if digits == CountryCodes.recognizedCode(forDigits: digits) {
            focusPhone(after: 0.15)
        } else if digits.count >= CountryCodes.maxLength {
            // No exact mapping, but the code slot is full → let typing continue.
            focusPhone(after: 0.15)
        }
    }

    private func focusPhone(after delay: TimeInterval) {
        guard focus != .phone else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                focus = .phone
            }
        }
    }

    // MARK: Actions

    private func continueToOTP() {
        guard isMinimallyValid else { return }
        haptics.impact(.light)
        focus = nil
        isOTPPresented = true
    }
}
