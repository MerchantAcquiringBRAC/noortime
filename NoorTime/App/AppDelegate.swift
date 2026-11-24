import UIKit
import UserNotifications

/// Lets a reminder show (with its sound) even while NoorTime is open on screen.
/// Without this, iOS stays silent for notifications that arrive while the app is in front.
final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationDelegate = ForegroundNotificationDelegate()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        return true
    }
}
