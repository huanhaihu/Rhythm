import AppKit
import AVFoundation

class SoundPlayer {
    private let settings: Settings
    private var audioPlayer: AVAudioPlayer?

    init(settings: Settings) {
        self.settings = settings
    }

    func playAlert() {
        play(soundName: settings.alertSound)
    }

    func playMicroAlert() {
        play(soundName: settings.microAlertSound)
    }

    func preview(soundName: String) {
        play(soundName: soundName)
    }

    private func play(soundName: String) {
        if soundName == "custom" && !settings.customSoundPath.isEmpty {
            let url = URL(fileURLWithPath: settings.customSoundPath)
            if let player = try? AVAudioPlayer(contentsOf: url) {
                audioPlayer = player
                player.play()
            }
        } else {
            NSSound(named: NSSound.Name(soundName))?.play()
        }
    }
}
