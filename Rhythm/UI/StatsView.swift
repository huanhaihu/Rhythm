import SwiftUI

struct StatsView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.dayStats.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                    Text("开始计时后，休息记录会显示在这里。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sessionStore.dayStats, id: \.date) { stats in
                        Section {
                            // Summary cards
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                StatCard(value: "\(stats.completedCycles)", label: "完整周期", color: .blue)
                                StatCard(value: "\(stats.manualRests)", label: "立即休息", color: .orange)
                                StatCard(value: "\(stats.microRests)", label: "微休息", color: .green)
                                StatCard(value: "\(stats.skippedCount)", label: "跳过次数", color: .red)
                                StatCard(value: "\(stats.resetCount)", label: "重置次数", color: .purple)
                                StatCard(value: stats.totalRestLabel, label: "总休息时长", color: .teal)
                            }
                            .padding(.vertical, 4)

                            // Session list
                            ForEach(stats.sessions.filter { $0.type != .reset }) { session in
                                SessionRow(session: session)
                            }
                        } header: {
                            Text(stats.date)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .cornerRadius(8)
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .frame(width: 20)
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.typeLabel)
                    .font(.body)
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationLabel)
                    .font(.body)
                if session.skipped {
                    Text("跳过")
                        .font(.caption2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch session.type {
        case .rest:      return session.wasManualTrigger ? "bolt.fill" : "moon.zzz"
        case .microRest: return "eye.slash"
        case .reset:     return "arrow.clockwise"
        }
    }

    private var iconColor: Color {
        switch session.type {
        case .rest:      return session.wasManualTrigger ? .orange : .blue
        case .microRest: return .green
        case .reset:     return .purple
        }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: session.startTime)
    }
}
