import SwiftUI

/// What iOS says about notification permission (simplified).
enum NotificationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
}

/// What the screens show about notification permission.
enum NotificationStatus: Equatable {
    case notSetUp
    case enabled
    case denied

    init(_ authorization: NotificationAuthorization) {
        switch authorization {
        case .notDetermined: self = .notSetUp
        case .authorized: self = .enabled
        case .denied: self = .denied
        }
    }

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
