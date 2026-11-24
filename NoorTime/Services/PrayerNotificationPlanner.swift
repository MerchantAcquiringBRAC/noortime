import Foundation

/// One reminder that should exist in iOS.
struct PlannedNotification: Equatable {
    let identifier: String
    let prayer: Prayer
    let fireDate: Date
}

/// Decides WHICH reminders to schedule. Pure logic: no iOS notification calls here.
///
/// Rolling window: iOS keeps at most 64 pending local notifications per app, so we schedule the
/// next 12 days (12 x 5 = 60 prayers) and rebuild the list every time the app opens.
struct PrayerNotificationPlanner {
    static let identifierPrefix = "noortime.prayer."
    static let daysAhead = 12
    /// Stays under the iOS limit of 64.
    static let maxNotifications = 60

    private let calculator: PrayerTimeCalculating

    init(calculator: PrayerTimeCalculating = AdjustedPrayerTimeCalculator.standard) {
        self.calculator = calculator
    }

    func plan(now: Date,
              location: PrayerLocation,
              settings: PrayerCalculationSettings,
              preferences: NotificationPreferences) -> [PlannedNotification] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = location.timeZone

        var planned: [PlannedNotification] = []

        for offset in 0..<Self.daysAhead {
            // A day that cannot be calculated is skipped; the other days still work.
            guard let day = calendar.date(byAdding: .day, value: offset, to: now),
                  let entries = try? calculator.entries(for: day, location: location, settings: settings) else {
                continue
            }
            let parts = calendar.dateComponents([.year, .month, .day], from: day)
            let dayKey = String(format: "%04ld%02ld%02ld", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)

            for entry in entries {
                // Never schedule the past (or the next second), never sunrise, never a switched-off prayer.
                guard entry.prayer.isPrayer,
                      preferences.isEnabled(entry.prayer),
                      entry.time > now.addingTimeInterval(1) else { continue }

                planned.append(PlannedNotification(
                    identifier: "\(Self.identifierPrefix)\(dayKey).\(entry.prayer.rawValue)",
                    prayer: entry.prayer,
                    fireDate: entry.time
                ))
            }
        }

        return Array(planned.sorted { $0.fireDate < $1.fireDate }.prefix(Self.maxNotifications))
    }
}
