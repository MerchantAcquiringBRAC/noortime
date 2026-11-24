import Foundation

enum TimeFormatting {
    /// Clock time such as "4:55 AM", shown in the given time zone
    /// (so a location's own time zone is used, not the phone's).
    static func clockString(_ date: Date,
                            timeZone: TimeZone,
                            locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Long date such as "Tuesday, 10 November 2026".
    static func longDateString(_ date: Date,
                               timeZone: TimeZone,
                               locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
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
        return String(format: "%02ld:%02ld:%02ld", hours, minutes, secs)
    }

    /// For Bengali, swaps 0-9 for ০-৯. Other languages are returned unchanged.
    static func localizedDigits(_ text: String, languageCode: String) -> String {
        guard languageCode == "bn" else { return text }
        let bengali: [Character] = Array("০১২৩৪৫৬৭৮৯")
        return String(text.map { (character: Character) -> Character in
            if character.isASCII, let digit = character.wholeNumberValue {
                return bengali[digit]
            }
            return character
        })
    }
}
