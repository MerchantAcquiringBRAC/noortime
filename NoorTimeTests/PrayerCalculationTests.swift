import XCTest
@testable import NoorTime

/// Tests the real Adhan-based calculation.
/// NOTE: these check that results are sensible and consistent. They do NOT prove
/// agreement with an official Bangladesh timetable; that comparison is still to be done.
final class PrayerCalculationTests: XCTestCase {
    private let service = AdhanPrayerTimeService()
    /// 11 November 2026, midday in Dhaka.
    private let day = TestSupport.date(2026, 11, 11, 12, 0)

    private func times(school: AsrSchool,
                       location: PrayerLocation = TestSupport.dhakaLocation,
                       method: CalculationMethodOption = .karachi,
                       date: Date? = nil) throws -> [Prayer: Date] {
        let settings = PrayerCalculationSettings(method: method, asrSchool: school)
        let list = try service.entries(for: date ?? day, location: location, settings: settings)
        return Dictionary(uniqueKeysWithValues: list.map { ($0.prayer, $0.time) })
    }

    func testReturnsSixEntriesInOrder() throws {
        let list = try service.entries(for: day,
                                       location: TestSupport.dhakaLocation,
                                       settings: .bangladeshDefault)
        XCTAssertEqual(list.map { $0.prayer }, Prayer.allCases)
        for index in 1..<list.count {
            XCTAssertLessThan(list[index - 1].time, list[index].time)
        }
    }

    func testDhakaTimesAreInSensibleRanges() throws {
        let t = try times(school: .hanafi)
        let m = { (prayer: Prayer) in TestSupport.minutesOfDay(t[prayer]!) }
        XCTAssertTrue((4 * 60 + 30...5 * 60 + 15).contains(m(.fajr)), "Fajr \(m(.fajr))")
        XCTAssertTrue((6 * 60...6 * 60 + 25).contains(m(.sunrise)), "Sunrise \(m(.sunrise))")
        XCTAssertTrue((11 * 60 + 30...12 * 60).contains(m(.dhuhr)), "Dhuhr \(m(.dhuhr))")
        XCTAssertTrue((15 * 60...16 * 60).contains(m(.asr)), "Asr \(m(.asr))")
        XCTAssertTrue((17 * 60...17 * 60 + 30).contains(m(.maghrib)), "Maghrib \(m(.maghrib))")
        XCTAssertTrue((18 * 60 + 15...18 * 60 + 45).contains(m(.isha)), "Isha \(m(.isha))")
    }

    func testHanafiAsrIsLaterThanShafiAndNothingElseChanges() throws {
        let hanafi = try times(school: .hanafi)
        let shafi = try times(school: .shafi)

        let gap = hanafi[.asr]!.timeIntervalSince(shafi[.asr]!) / 60
        XCTAssertGreaterThan(gap, 20, "Hanafi Asr should be clearly later than Shafi Asr")
        XCTAssertLessThan(gap, 90)

        for prayer in Prayer.allCases where prayer != .asr {
            XCTAssertEqual(hanafi[prayer], shafi[prayer], "\(prayer) should not depend on Asr school")
        }
    }

    func testAllTimesFallOnRequestedLocalDay() throws {
        let makkah = TimeZone(identifier: "Asia/Riyadh")!
        let newYork = TimeZone(identifier: "America/New_York")!
        let places: [PrayerLocation] = [
            TestSupport.dhakaLocation,
            PrayerLocation(latitude: 21.4225, longitude: 39.8262, timeZone: makkah),
            PrayerLocation(latitude: 40.7128, longitude: -74.0060, timeZone: newYork)
        ]
        for place in places {
            let noon = TestSupport.date(2026, 11, 11, 12, 0, in: place.timeZone)
            let list = try service.entries(for: noon, location: place, settings: .bangladeshDefault)
            for entry in list {
                let local = TestSupport.localDay(entry.time, in: place.timeZone)
                XCTAssertEqual(local.year, 2026)
                XCTAssertEqual(local.month, 11)
                XCTAssertEqual(local.day, 11, "\(entry.prayer) in \(place.timeZone.identifier)")
            }
        }
    }

    func testEarlyMorningInLocationStillUsesThatLocalDay() throws {
        // 00:30 in Dhaka on 11 Nov is still 10 Nov in UTC. The schedule must be for 11 Nov (Dhaka).
        let earlyMorning = TestSupport.date(2026, 11, 11, 0, 30)
        let atNoon = try times(school: .hanafi)
        let atEarly = try times(school: .hanafi, date: earlyMorning)
        XCTAssertEqual(atNoon, atEarly)
    }

    func testEasternCityPraysEarlierThanWesternCity() throws {
        // Sylhet (east) vs Khulna (west) are about 2.3 degrees apart = about 9 minutes at Dhuhr.
        let sylhet = PrayerLocation(latitude: 24.8949, longitude: 91.8687, timeZone: TestSupport.dhaka)
        let khulna = PrayerLocation(latitude: 22.8456, longitude: 89.5403, timeZone: TestSupport.dhaka)
        let east = try times(school: .hanafi, location: sylhet)
        let west = try times(school: .hanafi, location: khulna)
        let gap = west[.dhuhr]!.timeIntervalSince(east[.dhuhr]!) / 60
        XCTAssertGreaterThan(gap, 7)
        XCTAssertLessThan(gap, 12)
    }

    func testEveryCalculationMethodProducesTimes() throws {
        for method in CalculationMethodOption.allCases {
            let t = try times(school: .hanafi, method: method)
            XCTAssertEqual(t.count, Prayer.allCases.count, "\(method)")
        }
    }
}
