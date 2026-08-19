import SwiftUI

/// Top-level sections of the app.
enum RootTab: String, CaseIterable, Identifiable {
    case chats, contacts, calls, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chats: return "Chats"
        case .contacts: return "Contacts"
        case .calls: return "Calls"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .chats: return "bubble.left.and.bubble.right"
        case .contacts: return "person.2"
        case .calls: return "phone"
        case .settings: return "gearshape"
        }
    }

    /// Filled variant shown when the tab is selected.
    var iconSelected: String {
        switch self {
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .contacts: return "person.2.fill"
        case .calls: return "phone.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .chats: return "Shows your conversations"
        case .contacts: return "Shows your contacts"
        case .calls: return "Shows your call history"
        case .settings: return "Shows app settings"
        }
    }
}

/// Floating capsule tab bar with a real-time drag indicator (V3 §17–24).
///
/// The accent indicator tracks the finger's X coordinate continuously as a
/// fractional tab position (0.0 = Chats … 3.0 = Settings), stretching subtly
/// between slots, and springs onto the nearest tab on release. All drag
/// state stays local to this view — nothing outside is invalidated per frame,
/// which keeps the interaction smooth on 120 Hz displays.
struct FloatingTabBar: View {
    @Binding var selection: RootTab
    var unreadBadge: Int = 0
    var bottomSpacing: CGFloat = AppSpacing.sm
    var onCompose: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var haptics: HapticService

    // MARK: Drag state (local by design, V3 §47)

    /// Fractional indicator position: 0.0 = Chats, 1.0 = Contacts,
    /// 2.0 = Calls, 3.0 = Settings. Follows the finger in real time.
    @State private var indicatorPosition: CGFloat = 0
    @State private var isDragging = false
    /// One light haptic per crossed tab boundary — never per frame.
    @State private var lastHapticIndex: Int?
    /// Size of a single tab slot, measured from the live layout.
    @State private var slotSize: CGSize = .zero

    private let tabs = RootTab.allCases
    private var maxPosition: CGFloat { CGFloat(tabs.count - 1) }
    private var selectionIndex: Int { tabs.firstIndex(of: selection) ?? 0 }

    /// Tab highlighted right now: nearest to the finger while dragging,
    /// otherwise the committed selection.
    private var highlightedIndex: Int {
        guard isDragging else { return selectionIndex }
        return Int(min(max(indicatorPosition.rounded(), 0), maxPosition))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            capsule
            composeButton
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, bottomSpacing)
        .frame(maxWidth: .infinity)
        .onAppear { indicatorPosition = CGFloat(selectionIndex) }
        .onChange(of: selection) { _ in
            // Programmatic tab changes (taps elsewhere, deep links) must
            // keep the indicator glued to the committed selection.
            guard !isDragging else { return }
            moveIndicator(to: CGFloat(selectionIndex))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation")
    }

    // MARK: Capsule

    private var capsule: some View {
        tabRow
            .padding(.vertical, AppSpacing.xs)
            .padding(.horizontal, AppSpacing.xs)
            .background(GlassBackground(style: .capsule))
            .frame(maxWidth: 500)
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                tabItem(tab, index: index)
            }
        }
        .background(alignment: .leading) { selectionIndicator }
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        slotSize = CGSize(width: proxy.size.width / CGFloat(tabs.count),
                                          height: proxy.size.height)
                    }
                    .onChange(of: proxy.size.width) { width in
                        slotSize = CGSize(width: width / CGFloat(tabs.count),
                                          height: proxy.size.height)
                    }
            }
        }
        // The drag gesture wins only once the touch actually moves, so plain
        // taps still reach the individual tab buttons below.
        .highPriorityGesture(dragGesture)
    }

    // MARK: Indicator

    /// Accent capsule that follows the finger. Its leading edge is
    /// `indicatorPosition * slotWidth`; while dragging it stretches subtly,
    /// peaking halfway between two slots (V3 §20).
    private var selectionIndicator: some View {
        let inset: CGFloat = 3
        let fractional = indicatorPosition - floor(indicatorPosition)
        let stretch = isDragging && !reduceMotion
            ? 1 + 0.12 * sin(.pi * fractional)
            : 1
        let baseWidth = max(slotSize.width - inset * 2, 0)
        let width = baseWidth * stretch
        let extra = width - baseWidth
        return Capsule()
            .fill(Color.accentColor.opacity(0.16))
            .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 0.8))
            .frame(width: width, height: max(slotSize.height, 0))
            .offset(x: indicatorPosition * slotSize.width + inset - extra / 2)
    }

    // MARK: Drag gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard slotSize.width > 0 else { return }
                // Finger X → fractional tab position, clamped to the capsule.
                let raw = value.location.x / slotSize.width - 0.5
                let newPosition = min(max(raw, 0), maxPosition)
                let nearest = Int(newPosition.rounded())
                if !isDragging {
                    // Baseline for boundary haptics; no tick on touch-down.
                    isDragging = true
                    lastHapticIndex = nearest
                } else if nearest != lastHapticIndex {
                    lastHapticIndex = nearest
                    haptics.impact(.light)
                }
                // Direct assignment — no per-frame animation, so the
                // indicator is glued to the finger at display refresh rate.
                indicatorPosition = newPosition
            }
            .onEnded { value in
                defer {
                    isDragging = false
                    lastHapticIndex = nil
                }
                guard slotSize.width > 0 else { return }
                var target = Int(indicatorPosition.rounded())
                // A barely-moved finger keeps the original tab.
                if abs(value.translation.width) < 8 {
                    target = selectionIndex
                }
                target = min(max(target, 0), tabs.count - 1)
                if tabs[target] != selection {
                    haptics.impact(.light)
                }
                moveIndicator(to: CGFloat(target))
                selection = tabs[target]
            }
    }

    /// Animates the indicator onto a committed tab (release or tap).
    private func moveIndicator(to position: CGFloat) {
        if reduceMotion {
            indicatorPosition = position
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                indicatorPosition = position
            }
        }
    }

    // MARK: Tab items

    private func tabItem(_ tab: RootTab, index: Int) -> some View {
        let isHighlighted = highlightedIndex == index
        return Button {
            guard selection != tab else { return }
            haptics.selection()
            moveIndicator(to: CGFloat(index))
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isHighlighted ? tab.iconSelected : tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isHighlighted ? Color.accentColor : AppColors.secondary)
                    .overlay(alignment: .topTrailing) {
                        if tab == .chats, unreadBadge > 0, !isHighlighted {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 7, height: 7)
                                .offset(x: 3, y: -2)
                        }
                    }
                Text(tab.title)
                    .font(.system(size: 10, weight: isHighlighted ? .semibold : .regular))
                    .foregroundStyle(isHighlighted ? AppColors.primary : AppColors.secondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(isHighlighted ? [.isSelected] : [])
    }

    // MARK: Compose FAB

    private var composeButton: some View {
        Button(action: {
            haptics.impact(.light)
            onCompose()
        }) {
            ZStack {
                GlassBackground(style: GlassStyle(tint: .accentColor,
                                                  tintOpacity: 0.2,
                                                  cornerRadius: AppRadius.capsule,
                                                  strokeOpacity: 0.35,
                                                  shadowRadius: 14))
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(GlassPressStyle())
        .accessibilityLabel("New message")
        .accessibilityHint("Opens the compose screen")
    }
}

/// Convenience container that overlays content with the floating navigation.
struct FloatingNavigationBar<Content: View>: View {
    @Binding var selection: RootTab
    var unreadBadge: Int = 0
    var onCompose: () -> Void = {}
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FloatingTabBar(selection: $selection,
                               unreadBadge: unreadBadge,
                               onCompose: onCompose)
            }
    }
}
