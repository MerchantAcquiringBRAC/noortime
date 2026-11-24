import Foundation

/// Manual "add or subtract minutes" corrections, one value per prayer (and sunrise).
/// Everything starts at zero. Useful to match a local mosque timetable.
struct PrayerAdjustments: Codable, Equatable {
    /// Largest correction in either direction.
    static let range: ClosedRange<Int> = -30...30

    /// Only non-zero values are stored, so "all zero" always equals the default value.
    private(set) var values: [String: Int] = [:]

    var isZero: Bool { values.isEmpty }

    func minutes(for prayer: Prayer) -> Int {
        values[prayer.rawValue] ?? 0
    }

    /// Stores a correction, limited to -30...+30 minutes.
    mutating func set(_ minutes: Int, for prayer: Prayer) {
        let clamped = min(max(minutes, Self.range.lowerBound), Self.range.upperBound)
        if clamped == 0 {
            values.removeValue(forKey: prayer.rawValue)
        } else {
            values[prayer.rawValue] = clamped
        }
    }

    mutating func reset() {
        values.removeAll()
    }
}
