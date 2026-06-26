import SwiftUI
import AppKit
import Combine

// MARK: - App Router

class AppRouter: ObservableObject {
    static let shared = AppRouter()
    var openMainWindow: ((_ tab: Int) -> Void)?
    var showPopover: (() -> Void)?
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {

    // All state objects live here — only one owner, no timing issues
    private var settings: Settings?
    private var sessionStore: SessionStore?
    private var wordStore: WordStore?
    private var checkinStore: CheckinStore?
    private var noteReviewStore: NoteReviewStore?
    private var thoughtStore: ThoughtStore?
    private var reflectionStore: ReflectionStore?
    private var reportGenerator: MonthlyReportGenerator?
    private var soundPlayer: SoundPlayer?
    private var timerEngine: TimerEngine?
    private var overlayManager: OverlayWindowManager?
    private var dailyReminder: DailyReminder?

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var cancellable: AnyCancellable?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        enforceSingleInstance()
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])

        let s      = Settings()
        let store  = SessionStore()
        let words  = WordStore()
        let checkin = CheckinStore()
        let noteReviews = NoteReviewStore()
        let thoughts = ThoughtStore()
        let reflections = ReflectionStore()
        let generator = MonthlyReportGenerator(
            thoughtStore: thoughts,
            reflectionStore: reflections,
            settings: s
        )
        let sound  = SoundPlayer(settings: s)
        let engine = TimerEngine(settings: s, sessionStore: store, soundPlayer: sound)
        let overlay = OverlayWindowManager()

        engine.onOverlayNeeded = { [weak overlay, weak engine] show, isMicro in
            guard let overlay, let engine else { return }
            if show { overlay.show(isMicro: isMicro, timerEngine: engine) }
            else    { overlay.dismiss() }
        }

        settings      = s
        sessionStore  = store
        wordStore     = words
        checkinStore  = checkin
        noteReviewStore = noteReviews
        thoughtStore  = thoughts
        reflectionStore = reflections
        reportGenerator = generator
        soundPlayer   = sound
        timerEngine   = engine
        overlayManager = overlay

        AppRouter.shared.openMainWindow = { [weak self] tab in self?.openMainWindow(tab: tab) }
        AppRouter.shared.showPopover = { [weak self] in self?.showPopover() }

        setupStatusItem()
        setupPopover()

        dailyReminder = DailyReminder(
            settings: s,
            checkinStore: checkin,
            noteReviewStore: noteReviews
        )

        Task { [weak generator] in
            await generator?.generateIfNeeded()
        }

        // Warm up the local English-Chinese dictionary in the background so the first
        // translate query is instant.
        _ = DictionaryService.shared
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        guard let engine = timerEngine else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        updateButton(button, title: engine.menuBarTitle)
        button.target = self
        button.action = #selector(togglePopover)

        cancellable = engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak button, weak engine] _ in
                DispatchQueue.main.async {
                    guard let self, let button, let engine else { return }
                    self.updateButton(button, title: engine.menuBarTitle)
                }
            }
    }

    private func updateButton(_ button: NSStatusBarButton, title: String) {
        let img = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Rhythm")
        img?.isTemplate = true
        button.image = img
        button.imagePosition = .imageLeft
        button.title = " \(title)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    }

    // MARK: - Popover

    private func setupPopover() {
        guard let engine = timerEngine,
              let settings = settings,
              let store = sessionStore else { return }

        guard let words = wordStore,
              let checkin = checkinStore,
              let noteReviews = noteReviewStore,
              let thoughts = thoughtStore,
              let reflections = reflectionStore,
              let generator = reportGenerator else { return }
        let content = MenuBarContentView()
            .environmentObject(engine)
            .environmentObject(settings)
            .environmentObject(store)
            .environmentObject(words)
            .environmentObject(checkin)
            .environmentObject(noteReviews)
            .environmentObject(thoughts)
            .environmentObject(reflections)
            .environmentObject(generator)
            .tint(Color(nsColor: .controlAccentColor))
        let controller = NSHostingController(rootView: content)
        popover = NSPopover()
        popover?.contentViewController = controller
        popover?.behavior = .transient
        popover?.animates = false
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let popover, popover.isShown {
            closePopover()
        } else {
            // Recreate content each open so SwiftUI renders with full window context
            // (fixes toggle colors being gray on first render)
            setupPopover()
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown == true { return }
        setupPopover()
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
        if let m = eventMonitor { NSEvent.removeMonitor(m); eventMonitor = nil }
    }

    // MARK: - Main (Settings) Window

    private var mainViewSelectedTab = 0

    func openMainWindow(tab: Int = 0) {
        guard let engine = timerEngine,
              let settings = settings,
              let store = sessionStore,
              let words = wordStore,
              let checkin = checkinStore,
              let noteReviews = noteReviewStore,
              let thoughts = thoughtStore,
              let reflections = reflectionStore,
              let generator = reportGenerator,
              let sound = soundPlayer else { return }

        mainViewSelectedTab = tab

        if mainWindow == nil {
            let view = MainView(initialTab: tab)
                .environmentObject(engine)
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(words)
                .environmentObject(checkin)
                .environmentObject(noteReviews)
                .environmentObject(thoughts)
                .environmentObject(reflections)
                .environmentObject(generator)
                .environmentObject(sound)
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Rhythm"
            window.setContentSize(NSSize(width: 440, height: 560))
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()
            window.isReleasedWhenClosed = false
            mainWindow = window
        } else {
            let view = MainView(initialTab: tab)
                .environmentObject(engine)
                .environmentObject(settings)
                .environmentObject(store)
                .environmentObject(words)
                .environmentObject(checkin)
                .environmentObject(noteReviews)
                .environmentObject(thoughts)
                .environmentObject(reflections)
                .environmentObject(generator)
                .environmentObject(sound)
            mainWindow?.contentViewController = NSHostingController(rootView: view)
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Single Instance Guard

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

// MARK: - App Entry Point

@main
struct RhythmApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Minimal placeholder — no window is shown at launch.
        // All UI is driven by AppDelegate (NSStatusItem + NSPopover + NSWindow).
        SwiftUI.Settings { EmptyView() }
    }
}
