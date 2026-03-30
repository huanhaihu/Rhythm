import Foundation
import SwiftUI

class Settings: ObservableObject {
    @AppStorage("workDuration")          var workDuration: Int = 25 * 60
    @AppStorage("restDuration")          var restDuration: Int = 5 * 60
    @AppStorage("microRestEnabled")      var microRestEnabled: Bool = true
    @AppStorage("microRestDuration")     var microRestDuration: Int = 10
    @AppStorage("microRestIntervalMin")  var microRestIntervalMin: Int = 4 * 60
    @AppStorage("microRestIntervalMax")  var microRestIntervalMax: Int = 5 * 60
    @AppStorage("alertSound")            var alertSound: String = "Glass"
    @AppStorage("microAlertSound")       var microAlertSound: String = "Ping"
    @AppStorage("customSoundPath")       var customSoundPath: String = ""
    @AppStorage("autoStart")             var autoStart: Bool = true

    static let systemSounds = [
        "Basso", "Blow", "Bottle", "Frog", "Funk",
        "Glass", "Hero", "Morse", "Ping", "Pop",
        "Purr", "Sosumi", "Submarine", "Tink"
    ]
}
