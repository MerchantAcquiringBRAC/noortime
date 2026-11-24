import AVFoundation

/// Plays the reminder sound inside the app so the user can hear it.
/// (AVFoundation is used only for this preview; the real reminders are played by iOS.)
@MainActor
final class SoundPreviewPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    func toggle() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }

    func play() {
        guard let url = NotificationSound.url else { return }
        do {
            // .playback so the user can check the sound even if the Silent switch is on.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            guard newPlayer.play() else {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                return
            }
            player = newPlayer
            isPlaying = true
        } catch {
            player = nil
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            self.isPlaying = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
