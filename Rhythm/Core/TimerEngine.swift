import Foundation
import Combine

enum TimerState: Equatable {
    case idle
    case working
    case resting
    case microResting
}

class TimerEngine: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var workSecondsRemaining: Int = 0
    @Published var restSecondsRemaining: Int = 0

    // Called when overlay should appear/disappear
    var onOverlayNeeded: ((Bool, Bool) -> Void)?  // (show, isMicro)

    private let settings: Settings
    private let sessionStore: SessionStore
    private let soundPlayer: SoundPlayer
    private let screenLockMonitor: ScreenLockMonitor

    private var mainTimer: Timer?
    private var microRestTimer: Timer?
    private var restStartTime: Date?
    private var plannedRestDuration: Int = 0

    init(settings: Settings, sessionStore: SessionStore, soundPlayer: SoundPlayer) {
        self.settings = settings
        self.sessionStore = sessionStore
        self.soundPlayer = soundPlayer
        self.screenLockMonitor = ScreenLockMonitor()

        screenLockMonitor.onScreenLocked = { [weak self] in
            self?.handleScreenLocked()
        }
    }

    // MARK: - Public API

    func start() {
        guard state == .idle else { return }
        state = .working
        workSecondsRemaining = settings.workDuration
        startMainTimer()
        scheduleNextMicroRest()
    }

    func pause() {
        guard state == .working else { return }
        mainTimer?.invalidate()
        mainTimer = nil
        microRestTimer?.invalidate()
        microRestTimer = nil
        state = .idle
    }

    func skipCurrentRest() {
        switch state {
        case .resting:      finishRest(skipped: true)
        case .microResting: finishMicroRest(skipped: true)
        default: break
        }
    }

    func triggerRestNow() {
        guard state == .working else { return }
        workSecondsRemaining = 0
    }

    var menuBarTitle: String {
        switch state {
        case .idle:         return "已暂停"
        case .working:
            let m = workSecondsRemaining / 60
            let s = workSecondsRemaining % 60
            return String(format: "%d:%02d", m, s)
        case .resting:      return "休息中 \(restSecondsRemaining)s"
        case .microResting: return "微休息 \(restSecondsRemaining)s"
        }
    }

    var isRunning: Bool { state != .idle }

    // MARK: - Private

    private func startMainTimer() {
        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(mainTimer!, forMode: .common)
    }

    private func tick() {
        switch state {
        case .working:
            if workSecondsRemaining > 0 {
                workSecondsRemaining -= 1
            } else {
                beginRest()
            }
        case .resting:
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else {
                finishRest(skipped: false)
            }
        case .microResting:
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else {
                finishMicroRest(skipped: false)
            }
        case .idle:
            break
        }
    }

    private func beginRest() {
        microRestTimer?.invalidate()
        microRestTimer = nil
        state = .resting
        plannedRestDuration = settings.restDuration
        restSecondsRemaining = plannedRestDuration
        restStartTime = Date()
        soundPlayer.playAlert()
        onOverlayNeeded?(true, false)
    }

    private func finishRest(skipped: Bool) {
        let actual = skipped
            ? (plannedRestDuration - restSecondsRemaining)
            : plannedRestDuration

        sessionStore.save(session: Session(
            id: UUID(), type: .rest,
            startTime: restStartTime ?? Date(),
            plannedDuration: plannedRestDuration,
            actualDuration: max(actual, 0),
            skipped: skipped
        ))

        onOverlayNeeded?(false, false)
        state = .working
        workSecondsRemaining = settings.workDuration
        scheduleNextMicroRest()
    }

    private func scheduleNextMicroRest() {
        guard settings.microRestEnabled else { return }
        microRestTimer?.invalidate()
        let lo = TimeInterval(settings.microRestIntervalMin)
        let hi = TimeInterval(settings.microRestIntervalMax)
        let interval = TimeInterval.random(in: lo...hi)
        microRestTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.beginMicroRest()
        }
        RunLoop.main.add(microRestTimer!, forMode: .common)
    }

    private func beginMicroRest() {
        guard state == .working else { return }
        state = .microResting
        plannedRestDuration = settings.microRestDuration
        restSecondsRemaining = plannedRestDuration
        restStartTime = Date()
        soundPlayer.playMicroAlert()
        onOverlayNeeded?(true, true)
    }

    private func finishMicroRest(skipped: Bool) {
        let actual = skipped
            ? (plannedRestDuration - restSecondsRemaining)
            : plannedRestDuration

        sessionStore.save(session: Session(
            id: UUID(), type: .microRest,
            startTime: restStartTime ?? Date(),
            plannedDuration: plannedRestDuration,
            actualDuration: max(actual, 0),
            skipped: skipped
        ))

        onOverlayNeeded?(false, false)
        state = .working
        scheduleNextMicroRest()
    }

    private func handleScreenLocked() {
        mainTimer?.invalidate()
        mainTimer = nil
        microRestTimer?.invalidate()
        microRestTimer = nil
        onOverlayNeeded?(false, false)
        state = .idle
        workSecondsRemaining = 0
        restSecondsRemaining = 0
    }
}
