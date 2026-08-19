import SwiftUI

/// Centralized color tokens. Semantic colors adapt to light/dark automatically.
enum AppColors {

    // MARK: Semantic

    static var primary: Color { Color(uiColor: .label) }
    static var secondary: Color { Color(uiColor: .secondaryLabel) }
    static var tertiary: Color { Color(uiColor: .tertiaryLabel) }
    static var background: Color { Color(uiColor: .systemGroupedBackground) }
    static var surface: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var separator: Color { Color(uiColor: .separator) }
    static var destructive: Color { .red }

    // MARK: Bubble gradients

    static let outgoingBubble = LinearGradient(
        colors: [Color.accentColor, Color.accentColor.opacity(0.72)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: Ambient background

    static func ambientBackground(light: Bool) -> LinearGradient {
        light
            ? LinearGradient(colors: [Color(red: 0.93, green: 0.96, blue: 1.0),
                                      Color(red: 0.97, green: 0.94, blue: 1.0),
                                      Color(red: 0.92, green: 0.98, blue: 0.97)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.16),
                                      Color(red: 0.10, green: 0.07, blue: 0.18),
                                      Color(red: 0.05, green: 0.12, blue: 0.15)],
                             startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Avatar gradients

    static let avatarGradients: [LinearGradient] = [
        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.teal, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.brown, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.cyan, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    static func avatarGradient(_ index: Int) -> LinearGradient {
        avatarGradients[abs(index) % avatarGradients.count]
    }

    // MARK: Accent palette

    static let accentPalette: [Color] = [.blue, .purple, .pink, .orange, .green, .teal]
}
