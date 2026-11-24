import SwiftUI

/// All settings: language, theme, calculation, manual adjustments, reminders, sound, privacy.
struct SettingsView: View {
    @ObservedObject var appSettings: AppSettingsController
    @ObservedObject var notifications: NotificationController

    @StateObject private var preview = SoundPreviewPlayer()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var reminderPrayers: [Prayer] {
        Prayer.allCases.filter { $0.isPrayer }
    }

    var body: some View {
        NavigationStack {
            List {
                languageSection
                themeSection
                calculationSection
                adjustmentsSection
                permissionSection
                prayersSection
                soundSection

                Section(header: Text("settings.about.header")) {
                    Text("settings.adhanLimit")
                        .font(.footnote)
                        .foregroundStyle(NTColor.textSecondary)
                }

                Section(header: Text("settings.privacy.header")) {
                    Text("settings.privacy.body")
                        .font(.footnote)
                        .foregroundStyle(NTColor.textSecondary)
                }
            }
            .navigationTitle(Text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .onDisappear { preview.stop() }
        }
    }

    // MARK: - Language and theme

    private var languageSection: some View {
        Section(header: Text("settings.language.header")) {
            Picker(selection: $appSettings.settings.language) {
                ForEach(LanguageChoice.allCases) { choice in
                    languageName(choice).tag(choice)
                }
            } label: {
                Text("settings.language.label")
            }
        }
    }

    /// Language names are written in their own language so anyone can find theirs.
    @ViewBuilder
    private func languageName(_ choice: LanguageChoice) -> some View {
        switch choice {
        case .system: Text("settings.language.system")
        case .english: Text(verbatim: "English")
        case .bengali: Text(verbatim: "বাংলা")
        }
    }

    private var themeSection: some View {
        Section(header: Text("settings.theme.header")) {
            Picker(selection: $appSettings.settings.theme) {
                ForEach(ThemeChoice.allCases) { choice in
                    Text(choice.titleKey).tag(choice)
                }
            } label: {
                Text("settings.theme.label")
            }
        }
    }

    // MARK: - Calculation

    private var calculationSection: some View {
        Section(header: Text("settings.calculation.header"),
                footer: Text("settings.calculation.footer")) {
            Picker(selection: $appSettings.settings.calculation.method) {
                ForEach(CalculationMethodOption.allCases) { option in
                    Text(option.titleKey).tag(option)
                }
            } label: {
                Text("settings.calculation.method")
            }

            Picker(selection: $appSettings.settings.calculation.asrSchool) {
                ForEach(AsrSchool.allCases) { school in
                    Text(school.titleKey).tag(school)
                }
            } label: {
                Text("settings.calculation.asr")
            }
        }
    }

    private var adjustmentsSection: some View {
        Section(header: Text("settings.adjust.header"),
                footer: Text("settings.adjust.footer")) {
            ForEach(Prayer.allCases) { prayer in
                Stepper(value: adjustmentBinding(for: prayer), in: PrayerAdjustments.range) {
                    HStack {
                        Text(prayer.titleKey)
                        Spacer()
                        adjustmentLabel(appSettings.settings.calculation.adjustments.minutes(for: prayer))
                            .foregroundStyle(NTColor.textSecondary)
                    }
                }
            }

            if !appSettings.settings.calculation.adjustments.isZero {
                Button("settings.adjust.reset") {
                    appSettings.resetAdjustments()
                }
            }
        }
    }

    /// "+2 min", "-3 min" or "0 min".
    private func adjustmentLabel(_ minutes: Int) -> Text {
        let sign = minutes > 0 ? "+" : (minutes < 0 ? "-" : "")
        return Text(verbatim: sign) + Text("settings.adjust.minutes \(abs(minutes))")
    }

    private func adjustmentBinding(for prayer: Prayer) -> Binding<Int> {
        Binding(
            get: { appSettings.settings.calculation.adjustments.minutes(for: prayer) },
            set: { appSettings.setAdjustment($0, for: prayer) }
        )
    }

    // MARK: - Reminders

    private var permissionSection: some View {
        Section(header: Text("settings.notifications.header"),
                footer: Text("settings.notifications.footer")) {
            Label {
                Text(notifications.status.titleKey)
            } icon: {
                Image(systemName: notifications.status.symbolName)
                    .foregroundStyle(NTColor.gold)
            }

            if notifications.status == .notSetUp {
                Button("settings.notifications.enable") {
                    Task { await notifications.requestPermission() }
                }
            }
            if notifications.status == .denied {
                Button("common.openSettings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        }
    }

    private var prayersSection: some View {
        Section {
            ForEach(reminderPrayers) { prayer in
                Toggle(isOn: binding(for: prayer)) {
                    Label {
                        Text(prayer.titleKey)
                    } icon: {
                        Image(systemName: prayer.symbolName)
                            .foregroundStyle(NTColor.gold)
                    }
                }
            }
        }
    }

    private var soundSection: some View {
        Section(header: Text("settings.sound.header"),
                footer: Text("settings.sound.note")) {
            Button {
                preview.toggle()
            } label: {
                Label {
                    Text(preview.isPlaying
                         ? LocalizedStringKey("settings.sound.stop")
                         : LocalizedStringKey("settings.sound.preview"))
                } icon: {
                    Image(systemName: preview.isPlaying ? "stop.fill" : "play.fill")
                }
            }
        }
    }

    private func binding(for prayer: Prayer) -> Binding<Bool> {
        Binding(
            get: { notifications.preferences.isEnabled(prayer) },
            set: { newValue in
                Task { await notifications.setEnabled(prayer, newValue) }
            }
        )
    }
}
