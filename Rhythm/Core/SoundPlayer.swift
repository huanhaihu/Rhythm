import AppKit
import AVFoundation

class SoundPlayer: ObservableObject {
    private let settings: Settings
    private var audioPlayer: AVAudioPlayer?

    init(settings: Settings) {
        self.settings = settings
    }

    func playAlert() {
        play(soundName: settings.alertSound, customPath: settings.customSoundPath)
    }

    func playMicroAlert() {
        play(soundName: settings.microAlertSound, customPath: settings.customMicroSoundPath)
    }

    func preview(soundName: String) {
        play(soundName: soundName)
    }

    func previewFile(path: String) {
        let url = URL(fileURLWithPath: path)
        if let player = try? AVAudioPlayer(contentsOf: url) {
            audioPlayer = player
            player.play()
        }
    }

    private func play(soundName: String, customPath: String = "") {
        if soundName == "custom" && !customPath.isEmpty {
            let url = URL(fileURLWithPath: customPath)
            if let player = try? AVAudioPlayer(contentsOf: url) {
                audioPlayer = player
                player.play()
            }
        } else {
            NSSound(named: NSSound.Name(soundName))?.play()
        }
    }
}
