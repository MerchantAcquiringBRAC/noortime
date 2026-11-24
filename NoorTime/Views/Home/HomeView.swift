import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var location = LocationController()
    @StateObject private var notifications = NotificationController()
    @State private var sheet: HomeSheet?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private enum HomeSheet: Identifiable {
        case settings
        case location
        var id: Self { self }
    }

    var body: some View {
        ZStack {
            NTColor.background.ignoresSafeArea()

            // Re-draws every second so the countdown is live.
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                content(now: context.date)
            }
        }
        .sheet(item: $sheet) { item in
            switch item {
            case .settings:
                SettingsView(notifications: notifications)
            case .location:
                LocationPickerView(location: location)
            }
        }
        // A new GPS fix or a chosen city: recalculate the prayer times.
        .onChange(of: location.place) { newPlace in
            viewModel.setPlace(newPlace)
            Task { await syncNotifications() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                viewModel.refreshIfNeeded(now: Date())
                location.refreshAuthorization()
                Task {
                    await syncNotifications()
                    await location.refreshGPSIfNeeded()
                }
            }
        }
        .task {
            await syncNotifications()
            await location.refreshGPSIfNeeded()
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

                NotificationStatusBadge(status: notifications.status, action: handleNotificationTap)
            }
            .padding(.horizontal, NTLayout.screenPadding)
            .padding(.vertical, 12)
        }
        // Once a minute: rebuild the schedule if midnight has passed.
        .onChange(of: Int(now.timeIntervalSince1970 / 60)) { _ in
            viewModel.refreshIfNeeded(now: now)
        }
    }

    // MARK: - Notifications

    /// Re-plans the reminders for the current place (safe to call often).
    private func syncNotifications() async {
        await notifications.sync(location: viewModel.place.location, settings: viewModel.settings)
    }

    private func handleNotificationTap() {
        switch notifications.status {
        case .notSetUp:
            // The iOS permission pop-up appears only after the user taps this.
            Task { await notifications.requestPermission() }
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        case .enabled:
            sheet = .settings
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
                sheet = .settings
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

    /// "Dhaka, Bangladesh", or "Current location" while no city name is known.
    private var locationLabel: Text {
        if let title = viewModel.locationTitle {
            return Text(verbatim: title)
        }
        return Text("location.current")
    }

    private func locationAndDate(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                sheet = .location
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.place.source == .gps ? "location.fill" : "mappin.and.ellipse")
                        .font(.footnote)
                        .foregroundStyle(NTColor.gold)
                        .accessibilityHidden(true)
                    locationLabel
                        .font(.headline)
                        .foregroundStyle(NTColor.textPrimary)
                    Text(viewModel.place.source.labelKey)
                        .font(.caption)
                        .foregroundStyle(NTColor.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(NTColor.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("location.title"))

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

/// Tappable card showing the notification permission state.
struct NotificationStatusBadge: View {
    let status: NotificationStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: status.symbolName)
                    .foregroundStyle(NTColor.gold)
                    .accessibilityHidden(true)
                Text(status.titleKey)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(NTColor.textPrimary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(NTColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
