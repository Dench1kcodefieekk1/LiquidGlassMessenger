import Foundation

/// Shared, cached date/time formatters and relative labels.
/// Formatters are expensive to build; instances here are created once.
enum TimeFormatting {
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.doesRelativeDateFormatting = true
        return f
    }()

    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    static let lastSeenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let calendar = Calendar.current

    /// Compact timestamp for chat list rows: time today, weekday this week, short date otherwise.
    static func relativeDayLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return timeFormatter.string(from: date)
        }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now), date > weekAgo {
            return weekdayFormatter.string(from: date)
        }
        return dayFormatter.string(from: date)
    }

    /// Full label for chat date separators ("Today", "Yesterday", or a date).
    static func separatorLabel(for date: Date) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return dayFormatter.string(from: date)
    }

    /// "online" / "last seen at HH:mm" style subtitle.
    static func lastSeenLabel(for user: User) -> String {
        if user.isOnline { return "online" }
        return "last seen at \(lastSeenFormatter.string(from: user.lastSeen))"
    }

    /// Whether two dates fall on the same calendar day.
    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    /// Duration label for voice messages / calls, e.g. "0:42" or "14:12".
    static func durationLabel(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let rest = total % 60
        return String(format: "%d:%02d", minutes, rest)
    }
}
