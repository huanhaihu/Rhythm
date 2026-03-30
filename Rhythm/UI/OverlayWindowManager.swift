import AppKit
import SwiftUI

class OverlayWindowManager: ObservableObject {
    private var window: OverlayWindow?

    func show(isMicro: Bool, timerEngine: TimerEngine) {
        DispatchQueue.main.async {
            self.dismiss()
            guard let screen = NSScreen.main else { return }

            // Use visibleFrame so the menu bar stays accessible
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

            self.window = win
            win.makeKeyAndOrderFront(nil)
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            self.window?.orderOut(nil)
            self.window = nil
        }
    }
}
