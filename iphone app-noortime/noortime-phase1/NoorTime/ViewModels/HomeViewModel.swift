import Foundation

/// Drives the home screen.
///
/// PHASE 1 NOTE: the prayer times below are TEMPORARY SAMPLE values so the design
/// can be built and checked. Phase 2 replaces them with real calculations
/// (Adhan Swift). The screen shows a visible "sample times" notice until then.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var schedule: [PrayerEntry]
    @Published var notificationStatus: NotificationStatus = .notSetUp

    let timeZone: TimeZone
    let isSampleData = true

    init(now: Date = Date()) {
        let zone = TimeZone(identifier: "Asia/Dhaka") ?? .current
        self.timeZone = zone
        self.schedule = SampleSchedule.entries(for: now, timeZone: zone)
    }

    /// Rebuilds the schedule if the calendar day changed (e.g. after midnight).
    func refreshIfNeeded(now: Date) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let first = schedule.first,
              !calendar.isDate(first.time, inSameDayAs: now) else { return }
        schedule = SampleSchedule.entries(for: now, timeZone: timeZone)
    }

    /// The next real prayer (not sunrise) after `now`.
    /// After Isha it returns tomorrow's Fajr.
    func nextPrayer(after now: Date) -> PrayerEntry {
        if let upcoming = schedule.first(where: { $0.prayer.isPrayer && $0.time > now }) {
            return upcoming
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let fajr = schedule.first { $0.prayer == .fajr } ?? schedule[0]
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: fajr.time) ?? fajr.time
        return PrayerEntry(prayer: .fajr, time: tomorrow)
    }

    /// True when this row is the one to highlight.
    func isNext(_ entry: PrayerEntry, now: Date) -> Bool {
        let next = nextPrayer(after: now)
        return entry.prayer == next.prayer && entry.prayer.isPrayer
    }
}

/// TEMPORARY sample times (roughly Dhaka, November). Removed in Phase 2.
enum SampleSchedule {
    static func entries(for date: Date, timeZone: TimeZone) -> [PrayerEntry] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let day = calendar.startOfDay(for: date)

        let sample: [(Prayer, Int, Int)] = [
            (.fajr, 4, 55),
            (.sunrise, 6, 13),
            (.dhuhr, 11, 40),
            (.asr, 15, 25),
            (.maghrib, 17, 8),
            (.isha, 18, 28)
        ]

        return sample.compactMap { prayer, hour, minute in
            guard let time = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else {
                return nil
            }
            return PrayerEntry(prayer: prayer, time: time)
        }
    }
}
