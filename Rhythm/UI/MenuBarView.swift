import SwiftUI
import ServiceManagement

struct MenuBarContentView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    timerCard
                    settingsCard
                    recordsCard
                }
                .padding(12)
            }
            .frame(maxHeight: 400)
            footerBar
        }
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.cyan.opacity(0.25), .purple.opacity(0.25)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 32, height: 32)
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Rhythm")
                    .font(.system(size: 14, weight: .semibold))
                Text("专注与休息节奏")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            statusBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.12))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch timerEngine.state {
        case .idle:         return "已暂停"
        case .working:      return "专注中"
        case .resting:      return "休息中"
        case .microResting: return "微休息"
        }
    }

    private var statusColor: Color {
        switch timerEngine.state {
        case .idle:         return .secondary
        case .working:      return .blue
        case .resting:      return .green
        case .microResting: return .orange
        }
    }

    // MARK: - Timer Card

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("距离休息")
                .font(.system(size: 13, weight: .semibold))

            HStack(alignment: .bottom, spacing: 0) {
                Text(timerDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(countdownDisplay)
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: countdownDisplay)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private var timerDescription: String {
        switch timerEngine.state {
        case .idle:         return "点击「开始计时」以启动"
        case .working:      return "专注进行中，加油 💪"
        case .resting:      return "好好放松一下 🌿"
        case .microResting: return "眼睛休息中，稍等片刻"
        }
    }

    private var countdownDisplay: String {
        switch timerEngine.state {
        case .idle:
            let s = settings.workDuration
            return String(format: "%d:%02d", s / 60, s % 60)
        case .working:
            let s = timerEngine.workSecondsRemaining
            return String(format: "%d:%02d", s / 60, s % 60)
        case .resting, .microResting:
            let s = timerEngine.restSecondsRemaining
            return String(format: "%d:%02d", s / 60, s % 60)
        }
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("节奏设置")
                .font(.system(size: 13, weight: .semibold))
                .padding(.bottom, 10)

            stepperRow(
                label: "专注间隔",
                value: "\(settings.workDuration / 60) 分钟",
                canDecrement: settings.workDuration > 5 * 60,
                canIncrement: settings.workDuration < 120 * 60,
                onDecrement: { settings.workDuration -= 60 },
                onIncrement: { settings.workDuration += 60 }
            )

            cardDivider

            stepperRow(
                label: "休息时长",
                value: "\(settings.restDuration / 60) 分钟",
                canDecrement: settings.restDuration > 60,
                canIncrement: settings.restDuration < 30 * 60,
                onDecrement: { settings.restDuration -= 60 },
                onIncrement: { settings.restDuration += 60 }
            )

            cardDivider

            toggleRow(label: "微休息", isOn: $settings.microRestEnabled)

            cardDivider

            HStack {
                Text("开机启动")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { launchAtLoginEnabled },
                    set: { setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.75, anchor: .trailing)
                .frame(width: 42, height: 24)
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private func stepperRow(label: String, value: String,
                             canDecrement: Bool, canIncrement: Bool,
                             onDecrement: @escaping () -> Void,
                             onIncrement: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            HStack(spacing: 0) {
                Button(action: onDecrement) {
                    Text("−")
                        .font(.system(size: 17, weight: .light))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(canDecrement ? .primary : .secondary.opacity(0.4))
                .disabled(!canDecrement)

                Text(value)
                    .font(.system(size: 13))
                    .frame(minWidth: 60, alignment: .center)

                Button(action: onIncrement) {
                    Text("+")
                        .font(.system(size: 17, weight: .light))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(canIncrement ? .primary : .secondary.opacity(0.4))
                .disabled(!canIncrement)
            }
        }
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.75, anchor: .trailing)
                .frame(width: 42, height: 24)
        }
    }

    private var cardDivider: some View {
        Divider().padding(.vertical, 7)
    }

    // MARK: - Records Card

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近记录")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(totalCount) 次")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if recentSessions.isEmpty {
                Text("暂无记录")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentSessions.enumerated()), id: \.element.id) { index, session in
                        HStack(spacing: 6) {
                            Text(formatDate(session.startTime))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(typeLabel(session))
                                .font(.system(size: 12))
                                .foregroundColor(typeColor(session))
                            Text(formatDuration(session.actualDuration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 42, alignment: .trailing)
                        }
                        .padding(.vertical, 6)
                        if index < recentSessions.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private var recentSessions: [Session] {
        sessionStore.sessions
            .filter { $0.type != .reset }
            .sorted { $0.startTime > $1.startTime }
            .prefix(5)
            .map { $0 }
    }

    private var totalCount: Int {
        sessionStore.sessions.filter { $0.type != .reset }.count
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: date)
    }

    private func typeLabel(_ s: Session) -> String {
        switch s.type {
        case .reset:     return "重置"
        case .microRest: return "微休息"
        case .rest:
            if s.skipped           { return "跳过" }
            if s.wasManualTrigger  { return "立即休息" }
            return "完整休息"
        }
    }

    private func typeColor(_ s: Session) -> Color {
        switch s.type {
        case .reset:     return .secondary
        case .microRest: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .rest:
            if s.skipped          { return .orange }
            if s.wasManualTrigger { return Color(red: 0.2, green: 0.6, blue: 1.0) }
            return Color(red: 0.2, green: 0.75, blue: 0.4)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack(spacing: 8) {
            if timerEngine.isRunning {
                footerButton("立即休息") { timerEngine.triggerRestNow() }
                footerButton("重置计时") { timerEngine.resetWithCurrentSettings() }
                if timerEngine.state == .microResting {
                    footerButton("跳过微休息") { timerEngine.skipCurrentRest() }
                }
                footerButton("暂停") { timerEngine.pause() }
            } else {
                footerButton("开始计时", primary: true) { timerEngine.start() }
            }
            Spacer()
            Button("退出") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(Divider(), alignment: .top)
    }

    private func footerButton(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(primary ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(primary ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(primary ? Color.clear : Color.primary.opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Launch at Login

    private var launchAtLoginEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            if enabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
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
