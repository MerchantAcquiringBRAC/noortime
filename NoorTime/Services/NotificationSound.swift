import Foundation

/// The sound played by prayer reminders.
///
/// iOS rules for notification sounds: linear PCM / MP3 / AIFF / CAF / WAV, and shorter than
/// 30 seconds (a longer file is replaced by the default sound). The sound also follows the
/// iPhone's Silent switch and Focus settings, so it can never be promised.
///
/// IMPORTANT: the bundled file is a PLACEHOLDER chime made for this project. Before release,
/// replace `Resources/Sounds/adhan_short.wav` with a properly licensed short Adhan
/// (under 30 seconds, same file name). See README and LICENSES.md.
enum NotificationSound {
    static let resourceName = "adhan_short"
    static let fileExtension = "wav"
    static var fileName: String { "\(resourceName).\(fileExtension)" }
    static let maximumSeconds: TimeInterval = 30

    static var url: URL? {
        AppBundle.main.url(forResource: resourceName, withExtension: fileExtension)
    }
}
