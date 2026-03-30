import SwiftUI

/// Holds a reference to the SwiftUI openWindow action so MenuBarExtra can call it
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    var openMainWindow: (() -> Void)?
}

@main
struct RhythmApp: App {
    @StateObject private var settings: Settings
    @StateObject private var sessionStore: SessionStore
    @StateObject private var timerEngine: TimerEngine
    @StateObject private var soundPlayer: SoundPlayer
    @StateObject private var overlayManager: OverlayWindowManager

    init() {
        let s = Settings()
        let store = SessionStore()
        let sound = SoundPlayer(settings: s)
        let engine = TimerEngine(settings: s, sessionStore: store, soundPlayer: sound)
        let overlay = OverlayWindowManager()

        engine.onOverlayNeeded = { show, isMicro in
            if show { overlay.show(isMicro: isMicro, timerEngine: engine) }
            else     { overlay.dismiss() }
        }

        _settings      = StateObject(wrappedValue: s)
        _sessionStore  = StateObject(wrappedValue: store)
        _soundPlayer   = StateObject(wrappedValue: sound)
        _timerEngine   = StateObject(wrappedValue: engine)
        _overlayManager = StateObject(wrappedValue: overlay)

        if s.autoStart {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { engine.start() }
        }
    }

    var body: some Scene {
        WindowGroup("Rhythm", id: "main") {
            MainView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
                .environmentObject(soundPlayer)
                .withOpenWindowCapture()   // captures openWindow into AppRouter
        }
        .defaultSize(width: 440, height: 520)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
        } label: {
            MenuBarLabel(timerEngine: timerEngine)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Helper to capture openWindow from SwiftUI environment
private struct OpenWindowCapture: ViewModifier {
    @Environment(\.openWindow) private var openWindow

    func body(content: Content) -> some View {
        content.onAppear {
            AppRouter.shared.openMainWindow = {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

private extension View {
    func withOpenWindowCapture() -> some View {
        modifier(OpenWindowCapture())
    }
}
