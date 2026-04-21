import SwiftUI

struct CheckinStatsView: View {
    @EnvironmentObject var checkinStore: CheckinStore
    @EnvironmentObject var noteReviewStore: NoteReviewStore
    @State private var displayMonth: Date = Date()

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 14) {
            statsHeader
            calendarView
            legend
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                statTile(label: "本月健身", value: "\(checkinStore.monthCheckinCount)", tint: .green)
                statTile(label: "健身连续", value: "\(checkinStore.currentStreak)", tint: .green)
                statTile(label: "总健身", value: "\(checkinStore.totalCount)", tint: .green)
            }
            HStack(spacing: 8) {
                statTile(label: "本月笔记", value: "\(noteReviewStore.monthReviewCount)", tint: .blue)
                statTile(label: "笔记连续", value: "\(noteReviewStore.currentStreak)", tint: .blue)
                statTile(label: "总笔记", value: "\(noteReviewStore.totalCount)", tint: .blue)
            }
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
                        let reviewed = noteReviewStore.isReviewed(date)
                        let isToday = calendar.isDateInToday(date)
                        let anyActive = checked || reviewed
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isToday ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 12, weight: anyActive ? .semibold : .regular))
                                    .foregroundColor(.primary)
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 4, height: 4)
                                        .opacity(checked ? 1 : 0)
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 4, height: 4)
                                        .opacity(reviewed ? 1 : 0)
                                }
                                .frame(height: 5)
                            }
                        }
                        .frame(height: 34)
                    } else {
                        Color.clear.frame(height: 34)
                    }
                }
            }
            .background(.regularMaterial)
            .cornerRadius(8)
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("健身").font(.system(size: 10)).foregroundColor(.secondary)
            }
            HStack(spacing: 5) {
                Circle().fill(Color.blue).frame(width: 6, height: 6)
                Text("复习笔记").font(.system(size: 10)).foregroundColor(.secondary)
            }
            Spacer()
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
