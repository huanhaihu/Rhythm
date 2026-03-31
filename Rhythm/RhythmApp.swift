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

// One-shot flag: suppress the window only on first launch, not on user-requested opens
private class LaunchSuppressor {
    static var didSuppress = false
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
        // Disable macOS window state restoration so settings window doesn't auto-reopen
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])

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
    }

    var body: some Scene {
        WindowGroup("Rhythm", id: "main") {
            MainView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
                .environmentObject(soundPlayer)
                .withOpenWindowCapture()
                .onAppear {
                    // Hide on first launch only; user-triggered opens go through normally
                    guard !LaunchSuppressor.didSuppress else { return }
                    LaunchSuppressor.didSuppress = true
                    DispatchQueue.main.async {
                        NSApp.windows
                            .filter { $0.title == "Rhythm" }
                            .forEach { $0.orderOut(nil) }
                    }
                }
        }
        .defaultSize(width: 440, height: 520)
        .windowResizability(.contentSize)

        // Use title+systemImage form (not label closure) — on macOS 15 the label
        // closure form causes the icon to vanish when body re-evaluates every second.
        MenuBarExtra(timerEngine.menuBarTitle, systemImage: "waveform") {
            MenuBarContentView()
                .environmentObject(timerEngine)
                .environmentObject(settings)
                .environmentObject(sessionStore)
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
