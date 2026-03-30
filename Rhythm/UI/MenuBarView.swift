import SwiftUI

// Content shown in the MenuBarExtra dropdown
struct MenuBarContentView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stateTitle)
                        .font(.headline)
                    Text(stateSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Actions
            if timerEngine.isRunning {
                Button("立即休息") { timerEngine.triggerRestNow() }
                    .keyboardShortcut("b", modifiers: .command)
                Button("暂停计时") { timerEngine.pause() }
            } else {
                Button("开始计时") { timerEngine.start() }
                    .keyboardShortcut("s", modifiers: .command)
            }

            Divider()

            Button("打开设置...") { openSettings() }
                .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("退出 Rhythm") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        }
        .frame(width: 220)
    }

    private var stateTitle: String {
        switch timerEngine.state {
        case .idle:         return "已暂停"
        case .working:      return timerEngine.menuBarTitle
        case .resting:      return "休息中 🌿"
        case .microResting: return "微休息 👁"
        }
    }

    private var stateSubtitle: String {
        switch timerEngine.state {
        case .idle:         return "点击「开始计时」以启动"
        case .working:      return "距下次休息"
        case .resting:      return "好好放松一下"
        case .microResting: return "让眼睛休息一会儿"
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title == "Rhythm" {
            window.makeKeyAndOrderFront(nil)
            return
        }
        // If no window found, open via URL scheme or just activate
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Label shown in the menu bar itself
struct MenuBarLabel: View {
    @ObservedObject var timerEngine: TimerEngine

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "waveform")
                .imageScale(.small)
            Text(timerEngine.menuBarTitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
        }
    }
}
