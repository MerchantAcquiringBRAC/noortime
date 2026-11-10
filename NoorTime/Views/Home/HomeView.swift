import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSettings = false

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
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let next = viewModel.nextPrayer(after: now)

        ScrollView {
            VStack(spacing: NTLayout.spacing) {
                header
                locationAndDate(now: now)

                NextPrayerCard(entry: next, now: now, timeZone: viewModel.timeZone)

                prayerList(now: now)

                NotificationStatusBadge(status: viewModel.notificationStatus)

                if viewModel.isSampleData {
                    Text("home.sampleNotice")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(NTColor.textSecondary)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, NTLayout.screenPadding)
            .padding(.vertical, 12)
        }
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
                Text("home.sampleCity")
                    .font(.headline)
                    .foregroundStyle(NTColor.textPrimary)
                Text("home.locationStatus.sample")
                    .font(.caption)
                    .foregroundStyle(NTColor.textSecondary)
            }
            Text(TimeFormatting.longDateString(now, timeZone: viewModel.timeZone))
                .font(.subheadline)
                .foregroundStyle(NTColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func prayerList(now: Date) -> some View {
        VStack(spacing: 4) {
            ForEach(viewModel.schedule) { entry in
                PrayerRow(
                    entry: entry,
                    isNext: viewModel.isNext(entry, now: now),
                    timeZone: viewModel.timeZone
                )
            }
        }
        .padding(8)
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
