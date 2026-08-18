import SwiftUI

/// Typography tokens. All styles use Dynamic Type text styles so they scale
/// with the user's accessibility settings.
enum AppTypography {
    static var largeTitle: Font { .largeTitle.weight(.bold) }
    static var title: Font { .title2.weight(.semibold) }
    static var headline: Font { .headline }
    static var body: Font { .body }
    static var callout: Font { .callout }
    static var subheadline: Font { .subheadline }
    static var footnote: Font { .footnote }
    static var caption: Font { .caption }
    static var bubbleText: Font { .body }
    static var timestamp: Font { .caption2 }
}
