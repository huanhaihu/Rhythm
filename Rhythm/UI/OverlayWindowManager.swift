import AppKit
import SwiftUI

class OverlayWindowManager: ObservableObject {
    private var window: OverlayWindow?
    private var escMonitor: Any?

    func show(isMicro: Bool, timerEngine: TimerEngine) {
        DispatchQueue.main.async {
            self.dismiss()
            guard let screen = NSScreen.main else { return }

            let frame = screen.visibleFrame
            let win = OverlayWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.level = .floating + 1
            win.isOpaque = false
            win.backgroundColor = .clear
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let view = OverlayView(timerEngine: timerEngine, isMicro: isMicro)
            win.contentView = NSHostingView(rootView: view)
            win.onEscape = { timerEngine.skipCurrentRest() }

            // Use a local event monitor for ESC so we don't need to make the window key
            // (making key/main was disrupting the MenuBarExtra icon)
            self.escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak win] event in
                if event.keyCode == 53 { win?.onEscape?(); return nil }
                return event
            }

            self.window = win
            // orderFrontRegardless shows without forcing app activation or becoming main window
            win.orderFrontRegardless()
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            if let m = self.escMonitor { NSEvent.removeMonitor(m); self.escMonitor = nil }
            self.window?.orderOut(nil)
            self.window = nil
        }
    }
}
