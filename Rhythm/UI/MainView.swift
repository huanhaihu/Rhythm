import SwiftUI

struct MainView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @State private var selectedTab: Int

    init(initialTab: Int = 0) { _selectedTab = State(initialValue: initialTab) }

    var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(0)

            CombinedStatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
                .tag(1)
        }
        .frame(width: 440, height: 560)
    }
}

struct CombinedStatsView: View {
    @State private var section: Section = .focus

    enum Section: String, CaseIterable, Identifiable {
        case focus = "专注模式"
        case words = "语言学习"
        case checkin = "健身打卡"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                ForEach(Section.allCases) { s in Text(s.rawValue).tag(s) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            switch section {
            case .focus:
                StatsView()
            case .words:
                WordsView()
            case .checkin:
                CheckinStatsView()
            }
        }
    }
}
