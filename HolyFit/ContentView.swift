import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("운동", systemImage: "dumbbell.fill", value: 0) {
                WorkoutTabView()
            }
            Tab("식단", systemImage: "fork.knife", value: 1) {
                DietTabView()
            }
            Tab("통계", systemImage: "chart.line.uptrend.xyaxis", value: 2) {
                StatsTabView()
            }
            Tab("설정", systemImage: "gearshape.fill", value: 3) {
                SettingsTabView()
            }
        }
        .tint(AppColors.accent)
    }
}
