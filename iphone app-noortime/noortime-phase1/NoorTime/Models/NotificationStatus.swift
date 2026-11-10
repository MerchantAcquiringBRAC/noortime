import SwiftUI

/// What the home screen shows about notification permission.
/// Phase 4 will fill this with the real iOS permission state.
enum NotificationStatus {
    case notSetUp
    case enabled
    case denied

    var symbolName: String {
        switch self {
        case .notSetUp: return "bell.badge"
        case .enabled: return "bell.fill"
        case .denied: return "bell.slash.fill"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .notSetUp: return "notifications.status.notSetUp"
        case .enabled: return "notifications.status.enabled"
        case .denied: return "notifications.status.denied"
        }
    }
}
