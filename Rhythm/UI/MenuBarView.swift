import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var checkinStore: CheckinStore
    @EnvironmentObject var noteReviewStore: NoteReviewStore

    @State private var showImmediateBreakAlert = false

    private var isResting: Bool {
        timerEngine.state == .resting || timerEngine.state == .microResting
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            VStack(spacing: 8) {
                timerCard
                if isResting {
                    FlashcardCard()
                } else {
                    TranslateCard()
                    ThoughtCard()
                }
                recordsCard
            }
            .padding(12)
            footerBar
        }
        .frame(width: 350)
        // Use SwiftUI-native material — more stable than NSVisualEffectView inside MenuBarExtra
        .background(.ultraThinMaterial)
        .alert("今日已使用立即休息", isPresented: $showImmediateBreakAlert) {
            Button("确认") { /* user confirms skipping — do nothing */ }
            Button("取消", role: .cancel) { timerEngine.triggerRestNow() }
        } message: {
            Text("您今天已使用过 \(timerEngine.todayManualRestsCount) 次立即休息。确认则跳过本次，取消则立即开始休息。")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.cyan.opacity(0.30), .purple.opacity(0.30)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Rhythm")
                    .font(.system(size: 13, weight: .semibold))
                Text("专注与休息节奏")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            statusBadge
            Button {
                AppRouter.shared.openMainWindow?(0)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("打开设置")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.thinMaterial)
        .overlay(Divider().opacity(0.4), alignment: .bottom)
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch timerEngine.state {
        case .idle:         return "已暂停"
        case .paused:       return "已暂停"
        case .working:      return "专注中"
        case .resting:      return "休息中"
        case .microResting: return "微休息"
        }
    }

    private var statusColor: Color {
        switch timerEngine.state {
        case .idle, .paused: return .secondary
        case .working:       return .blue
        case .resting:       return .green
        case .microResting:  return .orange
        }
    }

    // MARK: - Timer Card

    private var timerCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("距离休息")
                        .font(.system(size: 13, weight: .semibold))
                    Text(timerDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(countdownDisplay)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: countdownDisplay)
            }

            Divider().opacity(0.4).padding(.vertical, 8)

            HStack(spacing: 10) {
                checkinButton(
                    label: "今日健身",
                    isActive: checkinStore.todayChecked,
                    streak: checkinStore.currentStreak,
                    color: .green
                ) {
                    checkinStore.todayChecked.toggle()
                }

                checkinButton(
                    label: "复习笔记",
                    isActive: noteReviewStore.todayReviewed,
                    streak: noteReviewStore.currentStreak,
                    color: .blue
                ) {
                    noteReviewStore.todayReviewed.toggle()
                }

                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    @ViewBuilder
    private func checkinButton(label: String, isActive: Bool, streak: Int, color: Color, action: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundColor(isActive ? color : .secondary.opacity(0.5))
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(isActive ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
            .focusable(false)

            if streak > 0 {
                Text("\(streak)")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
        }
    }

    private var timerDescription: String {
        switch timerEngine.state {
        case .idle:         return "点击「开始专注」以启动"
        case .paused:       return "已暂停，点击「继续专注」恢复"
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
        case .paused, .working:
            let s = timerEngine.workSecondsRemaining
            return String(format: "%d:%02d", s / 60, s % 60)
        case .resting, .microResting:
            let s = timerEngine.restSecondsRemaining
            return String(format: "%d:%02d", s / 60, s % 60)
        }
    }

    // MARK: - Records Card

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 7) {
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
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentSessions.enumerated()), id: \.element.id) { index, session in
                        HStack(spacing: 6) {
                            Text(formatDate(session.startTime))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(typeLabel(session))
                                .font(.system(size: 11))
                                .foregroundColor(typeColor(session))
                            Text(formatDuration(session.actualDuration))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.vertical, 5)
                        if index < recentSessions.count - 1 {
                            Divider().opacity(0.5)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    private var recentSessions: [Session] {
        sessionStore.sessions
            .filter { $0.type != .reset }
            .sorted { $0.startTime > $1.startTime }
            .prefix(1)
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
            if s.skipped          { return "跳过" }
            if s.wasManualTrigger { return "立即休息" }
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
        HStack(spacing: 6) {
            // 主按钮：开始专注 / 继续专注 / 暂停
            Group {
                if timerEngine.isPaused {
                    footerButton("继续专注", primary: true) { timerEngine.resume() }
                } else if timerEngine.isRunning {
                    footerButton("暂停") { timerEngine.pause() }
                } else {
                    footerButton("开始专注", primary: true) { timerEngine.start() }
                }
            }
            footerButton("立即休息", disabled: timerEngine.state != .working) {
                if timerEngine.todayManualRestsCount >= 1 {
                    showImmediateBreakAlert = true
                } else {
                    timerEngine.triggerRestNow()
                }
            }
            footerButton("重置计时", disabled: !timerEngine.isRunning && !timerEngine.isPaused) {
                timerEngine.resetWithCurrentSettings()
            }
            if timerEngine.state == .resting || timerEngine.state == .microResting {
                footerButton("跳过休息") { timerEngine.skipCurrentRest() }
            }
            Spacer()
            iconButton(systemName: "chart.bar.xaxis", help: "统计") {
                AppRouter.shared.openMainWindow?(1)
            }
            iconButton(systemName: "power", help: "退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.thinMaterial)
        .overlay(Divider().opacity(0.4), alignment: .top)
    }

    private func iconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(help)
    }

    private func footerButton(_ title: String,
                               primary: Bool = false,
                               disabled: Bool = false,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(primary ? Color.accentColor : Color.primary.opacity(0.06))
                .foregroundColor(disabled ? Color.secondary.opacity(0.4) : (primary ? .white : .primary))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            disabled ? Color.secondary.opacity(0.12)
                                     : (primary ? Color.clear : Color.primary.opacity(0.15)),
                            lineWidth: 1
                        )
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(disabled)
    }

}

// MARK: - Menu bar label

struct MenuBarLabel: View {
    @ObservedObject var engine: TimerEngine

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
                .imageScale(.small)
            Text(engine.menuBarTitle)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .monospacedDigit()
        }
    }
}
