import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack(spacing: 0) {
            // Status header
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(stateTitle)
                        .font(.headline)
                    Text(stateSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            VStack(spacing: 2) {
                if timerEngine.isRunning {
                    MenuButton(title: "立即休息", icon: "moon.zzz.fill") {
                        timerEngine.triggerRestNow()
                    }
                    MenuButton(title: "一键重置", icon: "arrow.clockwise") {
                        timerEngine.resetWithCurrentSettings()
                    }
                    if timerEngine.state == .microResting {
                        MenuButton(title: "跳过微休息", icon: "forward.fill") {
                            timerEngine.skipCurrentRest()
                        }
                    }
                    MenuButton(title: "暂停计时", icon: "pause.circle") {
                        timerEngine.pause()
                    }
                } else {
                    MenuButton(title: "开始计时", icon: "play.circle.fill") {
                        timerEngine.start()
                    }
                }
            }
            .padding(.vertical, 4)

            Divider()

            VStack(spacing: 2) {
                MenuButton(title: "打开设置...", icon: "gear") {
                    openMainWindow()
                }
                MenuButton(title: "退出 Rhythm", icon: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }

    private var stateTitle: String {
        switch timerEngine.state {
        case .idle:         return "已暂停"
        case .working:      return timerEngine.menuBarTitle
        case .resting:      return timerEngine.menuBarTitle
        case .microResting: return timerEngine.menuBarTitle
        }
    }

    private var stateSubtitle: String {
        switch timerEngine.state {
        case .idle:         return "点击「开始计时」以启动"
        case .working:      return "距下次休息"
        case .resting:      return "好好放松一下 🌿"
        case .microResting: return "眼睛休息中，稍等片刻"
        }
    }

    private func openMainWindow() {
        if let open = AppRouter.shared.openMainWindow {
            open()
        } else {
            // Fallback: try to bring any existing window to front
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
        }
    }
}

// Single menu action button with hover effect
struct MenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(isHovered ? .white : .secondary)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isHovered ? .white : .primary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor : Color.clear)
            .cornerRadius(5)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .padding(.horizontal, 6)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var timerEngine: TimerEngine

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
                .imageScale(.small)
            Text(timerEngine.menuBarTitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
        }
    }
}
