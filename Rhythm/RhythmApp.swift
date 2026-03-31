import SwiftUI

/// Holds a reference to open the settings window from the menu bar.
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    var openMainWindow: (() -> Void)?
}

/// Checks if another instance is already running and terminates with an alert if so.
private func enforceSingleInstance() {
    let bundleID = Bundle.main.bundleIdentifier ?? ""
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    if running.count > 1 {
        let alert = NSAlert()
        alert.messageText = "Rhythm 已在运行"
        alert.informativeText = "Rhythm 已经在菜单栏中运行了，无需重复启动。\n请查看屏幕右上角的菜单栏图标。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}

@main
struct RhythmApp: App {
    @StateObject private var settings: Settings
    @StateObject private var sessionStore: SessionStore
    @StateObject private var timerEngine: TimerEngine
    @StateObject private var soundPlayer: SoundPlayer
    @StateObject private var overlayManager: OverlayWindowManager

    init() {
        enforceSingleInstance()
        let s = Settings()
        let store = SessionStore()
        let sound = SoundPlayer(settings: s)
        let engine = TimerEngine(settings: s, sessionStore: store, soundPlayer: sound)
        let overlay = OverlayWindowManager()

        engine.onOverlayNeeded = { show, isMicro in
            if show { overlay.show(isMicro: isMicro, timerEngine: engine) }
            else     { overlay.dismiss() }
        }

        _settings       = StateObject(wrappedValue: s)
        _sessionStore   = StateObject(wrappedValue: store)
        _soundPlayer    = StateObject(wrappedValue: sound)
        _timerEngine    = StateObject(wrappedValue: engine)
        _overlayManager = StateObject(wrappedValue: overlay)

        // Wire up the settings opener using the macOS settings selector
        // (Settings scene never auto-opens on launch)
        AppRouter.shared.openMainWindow = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        // SwiftUI.Settings scene: opens only on demand (⌘, or "打开设置" button).
        // Unlike WindowGroup it does NOT auto-open on app launch.
        SwiftUI.Settings {
            MainView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
                .environmentObject(soundPlayer)
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
        } label: {
            MenuBarLabel(timerEngine: timerEngine)
        }
        .menuBarExtraStyle(.window)
    }
}
