import SwiftUI

/// One row in the daily prayer list.
struct PrayerRow: View {
    let entry: PrayerEntry
    let isNext: Bool
    let timeZone: TimeZone

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.prayer.symbolName)
                .font(.title3)
                .frame(width: 32)
                .foregroundStyle(isNext ? NTColor.emerald : NTColor.gold)
                .accessibilityHidden(true)

            Text(entry.prayer.titleKey)
                .font(.body.weight(isNext ? .bold : .regular))
                .foregroundStyle(NTColor.textPrimary)

            Spacer(minLength: 8)

            Text(TimeFormatting.clockString(entry.time, timeZone: timeZone))
                .font(.body.weight(isNext ? .bold : .regular).monospacedDigit())
                .foregroundStyle(isNext ? NTColor.emerald : NTColor.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(isNext ? NTColor.highlight : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
