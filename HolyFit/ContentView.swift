import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeededExercises") private var hasSeeded = false
    @State private var isSeeding = false

    var body: some View {
        TabView {
            Tab("운동", systemImage: "dumbbell.fill") {
                WorkoutTabView()
            }
            Tab("식단", systemImage: "fork.knife") {
                DietTabView()
            }
            Tab("통계", systemImage: "chart.line.uptrend.xyaxis") {
                StatsTabView()
            }
            Tab("설정", systemImage: "gearshape.fill") {
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
