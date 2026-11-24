import UserNotifications

/// The few notification-center actions the app needs.
/// The real version wraps iOS; tests use a stand-in that records what was scheduled.
@MainActor
protocol NotificationCenterProviding {
    func authorization() async -> NotificationAuthorization
    /// Shows the iOS permission pop-up if it has not been shown yet. Returns true if allowed.
    func requestAuthorization() async throws -> Bool
    func pendingIdentifiers() async -> [String]
    func removePending(identifiers: [String])
    func add(_ request: UNNotificationRequest) async throws
}

/// The real iOS notification center.
@MainActor
struct SystemNotificationCenter: NotificationCenterProviding {

    private var center: UNUserNotificationCenter { UNUserNotificationCenter.current() }

    func authorization() async -> NotificationAuthorization {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map { $0.identifier }
    }

    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }
}
