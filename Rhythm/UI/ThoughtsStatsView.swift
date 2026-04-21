import SwiftUI

struct ThoughtsStatsView: View {
    @EnvironmentObject var thoughtStore: ThoughtStore
    @EnvironmentObject var reflectionStore: ReflectionStore
    @EnvironmentObject var reportGenerator: MonthlyReportGenerator
    @EnvironmentObject var settings: Settings

    @State private var displayMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var generateError: String? = nil

    private let calendar = Calendar.current
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private var displayMonthKey: String { monthKeyFormatter.string(from: displayMonth) }

    private var isDisplayingCurrentMonth: Bool {
        calendar.isDate(displayMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                statsHeader
                calendarSection
                if let date = selectedDate, let t = thoughtStore.thought(for: date) {
                    selectedDayCard(date: date, thought: t)
                }
                monthlyReportCard
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statsHeader: some View {
        HStack(spacing: 10) {
            statTile(label: "本月记录", value: "\(thoughtStore.monthRecordCount)", tint: .blue)
            statTile(label: "连续天数", value: "\(thoughtStore.currentStreak)", tint: .orange)
            statTile(label: "总共记录", value: "\(thoughtStore.totalCount)", tint: .purple)
            statTile(label: "今日",
                     value: thoughtStore.hasThoughtToday ? "已记录" : "未记录",
                     tint: thoughtStore.hasThoughtToday ? .blue : .secondary)
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

    private var calendarSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth)!
                    selectedDate = nil
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
                    selectedDate = nil
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

                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let recorded = thoughtStore.isRecorded(date)
                        let isToday = calendar.isDateInToday(date)
                        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        Button {
                            selectedDate = isSelected ? nil : date
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(recorded ? Color.blue.opacity(0.22) : Color.clear)
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        isSelected ? Color.blue
                                            : (isToday ? Color.accentColor : Color.clear),
                                        lineWidth: 1.5
                                    )
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 12, weight: recorded ? .semibold : .regular))
                                    .foregroundColor(recorded ? .blue : .primary)
                            }
                            .frame(height: 30)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!recorded)
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

    private func selectedDayCard(date: Date, thought: DailyThought) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    selectedDate = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text(thought.text)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(8)
    }

    private var monthlyReportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(monthTitle) 感受月报")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                regenerateButton
            }

            reportBody

            if let err = generateError {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    @ViewBuilder
    private var regenerateButton: some View {
        if reportGenerator.isGenerating {
            ProgressView().controlSize(.small)
        } else if hasEntriesForDisplayMonth {
            Button {
                triggerGenerate()
            } label: {
                Text(reflectionStore.reflection(for: displayMonthKey) == nil ? "立即生成" : "重新生成")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(settings.claudeAPIKey.isEmpty ? Color.primary.opacity(0.06) : Color.accentColor)
                    .foregroundColor(settings.claudeAPIKey.isEmpty ? .secondary.opacity(0.5) : .white)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(settings.claudeAPIKey.isEmpty)
        }
    }

    private var hasEntriesForDisplayMonth: Bool {
        !thoughtStore.entries(inMonth: displayMonthKey).isEmpty
    }

    @ViewBuilder
    private var reportBody: some View {
        if let r = reflectionStore.reflection(for: displayMonthKey) {
            reflectionContent(r)
        } else if !hasEntriesForDisplayMonth {
            Text("本月暂无笔记，开始记录第一条随想吧。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        } else if settings.claudeAPIKey.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("未配置 Claude API Key")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                Text("前往「设置 → Claude API」填入 Key，即可自动生成月度感受总结。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        } else if isDisplayingCurrentMonth {
            Text("本月尚未结束，月底将自动生成。你也可以现在预览。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        } else {
            Text("暂无月报，点击右上角「立即生成」。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private func reflectionContent(_ r: MonthlyReflection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(r.summary)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if !r.themes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("主题")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    themeTags(r.themes)
                }
            }

            if !r.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("高光时刻")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    ForEach(Array(r.highlights.enumerated()), id: \.offset) { _, h in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").foregroundColor(.secondary)
                            Text(h)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Text("由 Claude 于 \(generatedAtText(r.generatedAt)) 基于 \(r.entryCount) 条笔记生成")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    private func themeTags(_ themes: [String]) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(themes, id: \.self) { t in
                Text(t)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
    }

    private func generatedAtText(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }

    private func triggerGenerate() {
        generateError = nil
        Task {
            do {
                try await reportGenerator.regenerate(monthKey: displayMonthKey)
            } catch {
                generateError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
