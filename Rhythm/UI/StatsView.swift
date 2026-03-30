import SwiftUI

struct StatsView: View {
    @EnvironmentObject var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                    Text("开始计时后，你的休息记录会显示在这里。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(sessionStore.groupedByDay, id: \.0) { day, sessions in
                        Section(header: daySummaryHeader(day: day, sessions: sessions)) {
                            ForEach(sessions) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 420, height: 400)
    }

    @ViewBuilder
    private func daySummaryHeader(day: String, sessions: [Session]) -> some View {
        let completed = sessions.filter { !$0.skipped }.count
        HStack {
            Text(day)
                .font(.headline)
            Spacer()
            Text("共 \(sessions.count) 次  完成 \(completed) 次")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack {
            Image(systemName: session.type == .rest ? "moon.zzz" : "eye.slash")
                .frame(width: 20)
                .foregroundColor(session.type == .rest ? .blue : .orange)

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
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: session.startTime)
    }
}
