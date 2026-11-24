import Foundation

/// Always points at the NoorTime app bundle (also correct when running unit tests).
enum AppBundle {
    private final class Token {}
    static let main = Bundle(for: Token.self)
}
