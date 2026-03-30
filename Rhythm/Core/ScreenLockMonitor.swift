import Foundation

class ScreenLockMonitor {
    var onScreenLocked: (() -> Void)?

    init() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(
            self,
            selector: #selector(handleScreenLocked),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        // Also reset on screensaver start
        dnc.addObserver(
            self,
            selector: #selector(handleScreenLocked),
            name: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handleScreenLocked() {
        DispatchQueue.main.async { self.onScreenLocked?() }
    }
}
