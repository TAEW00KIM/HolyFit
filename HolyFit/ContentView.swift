import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededExercises") private var hasSeeded = false
    @State private var isSeeding = false

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
        .onAppear {
            guard !hasSeeded, !isSeeding else { return }
            isSeeding = true
            let count = (try? modelContext.fetchCount(FetchDescriptor<Exercise>())) ?? 0
            if count == 0 {
                hasSeeded = ExerciseSeedData.seed(into: modelContext)
            } else {
                hasSeeded = true
            }
            isSeeding = false
        }
    }
}
