import SwiftUI

/// Holds a reference to the SwiftUI openWindow action so MenuBarExtra can call it
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    var openMainWindow: (() -> Void)?
}

/// Checks if another instance is already running and terminates with an alert if so
private func enforceSingleInstance() {
    let bundleID = Bundle.main.bundleIdentifier ?? ""
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    // More than 1 means another instance exists besides us
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

/// Hides the main settings window automatically on launch.
/// The user can still open it via "打开设置" in the menu bar.
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            NSApp.windows
                .filter { !($0 is NSPanel) }
                .forEach { $0.orderOut(nil) }
        }
    }
}

@main
struct RhythmApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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

        _settings      = StateObject(wrappedValue: s)
        _sessionStore  = StateObject(wrappedValue: store)
        _soundPlayer   = StateObject(wrappedValue: sound)
        _timerEngine   = StateObject(wrappedValue: engine)
        _overlayManager = StateObject(wrappedValue: overlay)

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
                .environmentObject(sessionStore)
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
