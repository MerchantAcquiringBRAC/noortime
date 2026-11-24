import SwiftUI

@main
struct NoorTimeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(NTColor.emerald)
        }
    }
}
