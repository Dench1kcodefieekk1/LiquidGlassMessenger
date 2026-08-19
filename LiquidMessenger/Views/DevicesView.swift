import SwiftUI
import UIKit

/// Telegram-style Devices screen. LiquidMessenger is fully local, so this
/// shows the single real session on the current device — no fabricated
/// remote sessions (V3 §42).
struct DevicesView: View {
    private var deviceName: String { UIDevice.current.name }
    private var systemVersion: String { "iOS \(UIDevice.current.systemVersion)" }
    private var modelName: String { UIDevice.current.model }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "LiquidMessenger \(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.16))
                            .frame(width: 48, height: 48)
                        Image(systemName: "iphone")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .font(AppTypography.callout.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                        Text("\(modelName) · \(systemVersion)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondary)
                    }
                    Spacer()
                    GlassBadge(text: "Current")
                }
                .padding(.vertical, AppSpacing.xxs)
                .accessibilityElement(children: .combine)

                infoRow(icon: "app.badge", title: "Application", value: appVersion)
                infoRow(icon: "clock", title: "Session", value: "Active now")
            } header: {
                Text("This Device")
            } footer: {
                Text("LiquidMessenger runs entirely on this device. There are no other sessions and no server synchronization.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primary)
            Spacer()
            Text(value)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
