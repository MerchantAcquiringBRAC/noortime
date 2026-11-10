import Foundation

enum TimeFormatting {
    /// Clock time such as "4:55 AM", shown in the given time zone
    /// (so a location's own time zone is used, not the phone's).
    static func clockString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Long date such as "Tuesday, 10 November 2026".
    static func longDateString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEEddMMMMyyyy")
        return formatter.string(from: date)
    }

    /// Countdown such as "02:41:09". Never negative.
    static func countdownString(seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
