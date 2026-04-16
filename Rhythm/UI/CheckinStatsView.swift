import SwiftUI

struct CheckinStatsView: View {
    @EnvironmentObject var checkinStore: CheckinStore
    @State private var displayMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 16) {
            statsHeader
            calendarView
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsHeader: some View {
        HStack(spacing: 10) {
            statTile(label: "本月打卡", value: "\(checkinStore.monthCheckinCount)", tint: .green)
            statTile(label: "连续天数", value: "\(checkinStore.currentStreak)", tint: .orange)
            statTile(label: "总共打卡", value: "\(checkinStore.totalCount)", tint: .blue)
            statTile(label: "今日", value: checkinStore.todayChecked ? "已打卡" : "未打卡",
                     tint: checkinStore.todayChecked ? .green : .secondary)
        }
    }

    private func statTile(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .cornerRadius(8)
    }

    private var calendarView: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()
                Text(monthTitle)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()

                Button {
                    displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(height: 20)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    if let date {
                        let checked = checkinStore.isChecked(date)
                        let isToday = calendar.isDateInToday(date)
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(checked ? Color.green.opacity(0.25) : Color.clear)
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 12, weight: checked ? .semibold : .regular))
                                .foregroundColor(checked ? .green : .primary)
                        }
                        .frame(height: 30)
                    } else {
                        Color.clear.frame(height: 30)
                    }
                }
            }
            .background(.regularMaterial)
            .cornerRadius(8)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: displayMonth)
    }

    private var daysInMonth: [Date?] {
        let comps = calendar.dateComponents([.year, .month], from: displayMonth)
        guard let first = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: first) else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        var days: [Date?] = Array(repeating: nil, count: weekday - 1)
        for day in range {
            var c = comps
            c.day = day
            days.append(calendar.date(from: c))
        }
        return days
    }
}
