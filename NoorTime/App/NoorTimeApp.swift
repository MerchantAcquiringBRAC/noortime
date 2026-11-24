import SwiftUI

@main
struct NoorTimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appSettings = AppSettingsController()

    var body: some Scene {
        WindowGroup {
            HomeView(appSettings: appSettings)
                .tint(NTColor.emerald)
                // The language and theme chosen in Settings apply to the whole app, sheets included.
                .environment(\.locale, appSettings.locale)
                .preferredColorScheme(appSettings.colorScheme)
        }
    }
}
