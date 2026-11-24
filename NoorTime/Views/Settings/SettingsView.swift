import SwiftUI

/// Phase 4: prayer reminders. Language, theme and Asr school are added in Phase 5.
struct SettingsView: View {
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
                permissionSection
                prayersSection
                soundSection

                Section {
                    Text("settings.comingSoon")
                        .foregroundStyle(NTColor.textSecondary)
                }

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

    // MARK: - Sections

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
