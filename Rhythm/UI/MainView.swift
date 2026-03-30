import SwiftUI

struct MainView: View {
    @EnvironmentObject var timerEngine: TimerEngine
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(0)

            StatsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
                .tag(1)
        }
        .frame(width: 440, height: 520)
    }
}
