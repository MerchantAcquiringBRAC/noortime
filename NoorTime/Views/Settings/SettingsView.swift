import SwiftUI

/// PHASE 1 placeholder. Real settings (language, theme, Asr school,
/// per-prayer notifications) arrive in Phases 3-5.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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
        }
    }
}

#Preview {
    SettingsView()
}
