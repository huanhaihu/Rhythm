import SwiftUI

@main
struct RhythmApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var overlayManager = OverlayWindowManager()

    // These need manual init to wire dependencies
    @StateObject private var timerEngine: TimerEngine
    @StateObject private var soundPlayer: SoundPlayer

    init() {
        let s = Settings()
        let store = SessionStore()
        let sound = SoundPlayer(settings: s)
        let engine = TimerEngine(settings: s, sessionStore: store, soundPlayer: sound)
        let overlay = OverlayWindowManager()

        engine.onOverlayNeeded = { show, isMicro in
            if show {
                overlay.show(isMicro: isMicro, timerEngine: engine)
            } else {
                overlay.dismiss()
            }
        }

        _settings = StateObject(wrappedValue: s)
        _sessionStore = StateObject(wrappedValue: store)
        _soundPlayer = StateObject(wrappedValue: sound)
        _timerEngine = StateObject(wrappedValue: engine)
        _overlayManager = StateObject(wrappedValue: overlay)

        if s.autoStart {
            // Delay to ensure the app is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                engine.start()
            }
        }
    }

    var body: some Scene {
        // Main settings/stats window
        WindowGroup("Rhythm") {
            MainView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
                .environmentObject(soundPlayer)
        }
        .defaultSize(width: 440, height: 520)
        .windowResizability(.contentSize)

        // Menu bar extra
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(timerEngine: timerEngine)
        }
        .menuBarExtraStyle(.menu)
    }
}
