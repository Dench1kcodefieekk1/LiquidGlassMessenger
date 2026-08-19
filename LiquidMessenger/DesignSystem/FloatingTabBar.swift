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

/// Floating capsule tab bar with glass material, animated selection,
/// badges, haptics and an attached circular action button.
struct FloatingTabBar: View {
    @Binding var selection: RootTab
    var unreadBadge: Int = 0
    var bottomSpacing: CGFloat = AppSpacing.sm
    var onCompose: () -> Void = {}

    @Namespace private var selectionNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var haptics: HapticService

    /// Tab highlighted while a finger drags across the capsule.
    @State private var dragHover: RootTab?
    @State private var capsuleWidth: CGFloat = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            capsule
            composeButton
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, bottomSpacing)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation")
    }

    // MARK: Capsule

    private var capsule: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .padding(.horizontal, AppSpacing.xs)
        .background(GlassBackground(style: .capsule))
        .frame(maxWidth: 500)
        .background(
            GeometryReader { proxy in
                Color.clear.onAppear { capsuleWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { capsuleWidth = $0 }
            }
        )
        // Interactive drag: hold the capsule and slide across the tabs;
        // the tab under the finger highlights and is selected on release.
        // Taps still reach the individual tab buttons (highPriorityGesture
        // only wins once the touch actually moves).
        .highPriorityGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    let hovered = tab(atX: value.location.x)
                    if hovered != dragHover {
                        dragHover = hovered
                        if let hovered {
                            haptics.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selection = hovered
                            }
                        }
                    }
                }
                .onEnded { value in
                    if let target = tab(atX: value.location.x) {
                        if target != selection {
                            haptics.impact(.light)
                        }
                        if reduceMotion {
                            selection = target
                        } else {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                selection = target
                            }
                        }
                    }
                    dragHover = nil
                }
        )
    }

    /// Maps a horizontal position inside the capsule to the tab beneath it.
    private func tab(atX x: CGFloat) -> RootTab? {
        guard capsuleWidth > 0 else { return nil }
        let tabs = RootTab.allCases
        let slot = capsuleWidth / CGFloat(tabs.count)
        let index = Int(x / slot)
        guard index >= 0, index < tabs.count else { return nil }
        return tabs[index]
    }

    private func tabItem(_ tab: RootTab) -> some View {
        let isSelected = selection == tab
        let isHovered = dragHover == tab
        return Button {
            guard selection != tab else { return }
            haptics.selection()
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                    selection = tab
                }
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? tab.iconSelected : tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.accentColor : AppColors.secondary)
                    .scaleEffect(isHovered && !reduceMotion ? 1.12 : 1)
                    .overlay(alignment: .topTrailing) {
                        if tab == .chats, unreadBadge > 0, !isSelected {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 7, height: 7)
                                .offset(x: 3, y: -2)
                        }
                    }
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.secondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor.opacity(0.16))
                        .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 0.8))
                        .matchedGeometryEffect(id: "tab.selection", in: selectionNamespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
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
