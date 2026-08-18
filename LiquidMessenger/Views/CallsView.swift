import SwiftUI

/// Call history. UI-only; the shape of the data supports a future CallKit integration.
struct CallsView: View {
    private let callService = AppContainer.callService
    @EnvironmentObject private var haptics: HapticService
    @State private var filter: CallFilter = .all

    enum CallFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case missed = "Missed"
        var id: String { rawValue }
    }

    private var visibleCalls: [Call] {
        filter == .missed ? callService.calls.filter { $0.direction == .missed } : callService.calls
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(CallFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(visibleCalls) { call in
                    row(call)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Calls")
    }

    private func row(_ call: Call) -> some View {
        HStack(spacing: AppSpacing.sm) {
            AvatarView(name: call.contactName,
                       gradientIndex: call.gradientIndex,
                       size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(call.contactName)
                    .font(AppTypography.headline)
                    .foregroundStyle(call.direction == .missed ? AppColors.destructive : AppColors.primary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: directionIcon(call.direction))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(directionColor(call.direction))
                    Text(subtitle(call))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(TimeFormatting.relativeDayLabel(for: call.date))
                    .font(AppTypography.timestamp)
                    .foregroundStyle(AppColors.secondary)
                Image(systemName: call.kind == .video ? "video" : "phone")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, AppSpacing.xxs)
        .contentShape(Rectangle())
        .onTapGesture { haptics.impact(.light) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: call))
    }

    private func directionIcon(_ direction: CallDirection) -> String {
        switch direction {
        case .incoming: return "arrow.down.left"
        case .outgoing: return "arrow.up.right"
        case .missed: return "arrow.down.left"
        }
    }

    private func directionColor(_ direction: CallDirection) -> Color {
        switch direction {
        case .incoming: return .green
        case .outgoing: return Color.accentColor
        case .missed: return .red
        }
    }

    private func subtitle(_ call: Call) -> String {
        switch call.direction {
        case .missed:
            return "Missed \(call.kind.rawValue) call"
        case .incoming, .outgoing:
            if let duration = call.duration {
                return "\(call.direction == .incoming ? "Incoming" : "Outgoing") · \(TimeFormatting.durationLabel(duration))"
            }
            return call.direction == .incoming ? "Incoming" : "Outgoing"
        }
    }

    private func accessibilityLabel(for call: Call) -> String {
        "\(call.contactName), \(call.direction.rawValue) \(call.kind.rawValue) call, \(TimeFormatting.relativeDayLabel(for: call.date))"
    }
}
