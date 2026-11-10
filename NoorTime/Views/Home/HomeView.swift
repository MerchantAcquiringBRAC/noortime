import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            NTColor.background.ignoresSafeArea()

            // Re-draws every second so the countdown is live.
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                content(now: context.date)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.refreshIfNeeded(now: Date())
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        ScrollView {
            VStack(spacing: NTLayout.spacing) {
                header
                locationAndDate(now: now)

                if let schedule = viewModel.schedule {
                    let next = schedule.next(after: now)
                    NextPrayerCard(entry: next, now: now, timeZone: viewModel.timeZone)
                    prayerList(schedule: schedule, next: next)
                    calculationNote
                } else {
                    errorCard
                }

                NotificationStatusBadge(status: viewModel.notificationStatus)
            }
            .padding(.horizontal, NTLayout.screenPadding)
            .padding(.vertical, 12)
        }
        // Once a minute: rebuild the schedule if midnight has passed.
        .onChange(of: Int(now.timeIntervalSince1970 / 60)) { _ in
            viewModel.refreshIfNeeded(now: now)
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(NTColor.emerald)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: 0xE8C877))
            }
            .frame(width: 42, height: 42)
            .accessibilityHidden(true)

            Text("app.name")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(NTColor.textPrimary)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(NTColor.emerald)
                    .frame(width: 44, height: 44)
                    .background(NTColor.card)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text("settings.title"))
        }
    }

    private func locationAndDate(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(NTColor.gold)
                    .accessibilityHidden(true)
                Text(verbatim: viewModel.locationTitle)
                    .font(.headline)
                    .foregroundStyle(NTColor.textPrimary)
                Text("home.locationStatus.default")
                    .font(.caption)
                    .foregroundStyle(NTColor.textSecondary)
            }
            Text(TimeFormatting.longDateString(now, timeZone: viewModel.timeZone))
                .font(.subheadline)
                .foregroundStyle(NTColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prayerList(schedule: DailyPrayerSchedule, next: PrayerEntry) -> some View {
        VStack(spacing: 4) {
            ForEach(schedule.entries) { entry in
                PrayerRow(
                    entry: entry,
                    // Highlight only when the next prayer is still today's.
                    isNext: entry.prayer.isPrayer && entry.time == next.time,
                    timeZone: viewModel.timeZone
                )
            }
        }
        .padding(8)
        .ntCard()
    }

    private var calculationNote: some View {
        VStack(spacing: 4) {
            (Text(viewModel.settings.method.titleKey)
                + Text(verbatim: " · ")
                + Text(viewModel.settings.asrSchool.titleKey))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(NTColor.textSecondary)

            Text("home.method.note")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(NTColor.textSecondary)
        }
        .padding(.horizontal)
    }

    private var errorCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(NTColor.gold)
                .accessibilityHidden(true)
            Text("home.error.title")
                .font(.headline)
                .foregroundStyle(NTColor.textPrimary)
            Text("home.error.body")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(NTColor.textSecondary)
            Button("home.error.retry") {
                viewModel.reload()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .ntCard()
    }
}

/// Small pill showing the notification permission state.
struct NotificationStatusBadge: View {
    let status: NotificationStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.symbolName)
                .foregroundStyle(NTColor.gold)
                .accessibilityHidden(true)
            Text(status.titleKey)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NTColor.textPrimary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(NTColor.card)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
}
