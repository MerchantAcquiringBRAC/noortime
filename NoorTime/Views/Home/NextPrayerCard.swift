import SwiftUI

/// Big green card: next prayer name, its time, and the live countdown.
struct NextPrayerCard: View {
    let entry: PrayerEntry
    let now: Date
    let timeZone: TimeZone

    /// True after Isha, when the next prayer is tomorrow's Fajr.
    private var isTomorrow: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return !calendar.isDate(entry.time, inSameDayAs: now)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("home.nextPrayer")
                .font(.subheadline.weight(.semibold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(NTColor.goldOnHero)

            Text(entry.prayer.titleKey)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            HStack(spacing: 8) {
                if isTomorrow {
                    Text("home.tomorrow")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NTColor.heroTop)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 10)
                        .background(NTColor.goldOnHero)
                        .clipShape(Capsule())
                }
                Text(TimeFormatting.clockString(entry.time, timeZone: timeZone))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Text(TimeFormatting.countdownString(seconds: entry.time.timeIntervalSince(now)))
                .font(.system(.largeTitle, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.top, 4)

            Text("home.remaining")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [NTColor.heroTop, NTColor.heroBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: NTLayout.cornerRadius + 6, style: .continuous))
        .shadow(color: NTColor.heroTop.opacity(0.35), radius: 16, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }
}
