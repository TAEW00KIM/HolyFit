import Foundation

enum WorkoutGoal: String, CaseIterable, Identifiable {
    case push = "밀기 (가슴/어깨/삼두)"
    case pull = "당기기 (등/이두)"
    case legs = "하체"
    case upperBody = "상체"
    case lowerBody = "하체 집중"
    case fullBody = "전신"
    case chestBack = "가슴 + 등"
    case shoulderArms = "어깨 + 팔"

    var id: String { rawValue }

    var targetGroups: [MuscleGroup] {
        switch self {
        case .push: return [.chest, .shoulders, .triceps]
        case .pull: return [.back, .biceps]
        case .legs: return [.legs]
        case .lowerBody: return [.legs, .core]
        case .upperBody: return [.chest, .back, .shoulders, .biceps, .triceps]
        case .fullBody: return [.chest, .back, .shoulders, .legs, .biceps, .triceps, .core, .fullBody]
        case .chestBack: return [.chest, .back]
        case .shoulderArms: return [.shoulders, .biceps, .triceps]
        }
    }

    var icon: String {
        switch self {
        case .push: return "arrow.right.circle.fill"
        case .pull: return "arrow.left.circle.fill"
        case .legs, .lowerBody: return "figure.walk"
        case .upperBody: return "figure.arms.open"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .chestBack: return "arrow.left.arrow.right"
        case .shoulderArms: return "hand.raised.fill"
        }
    }
}

enum WorkoutDuration: String, CaseIterable, Identifiable {
    case short = "30분"
    case medium = "45분"
    case long = "60분"
    case extraLong = "90분"

    var id: String { rawValue }
    var exerciseCount: Int {
        switch self {
        case .short: return 4
        case .medium: return 5
        case .long: return 6
        case .extraLong: return 8
        }
    }
}

struct GeneratedRoutine {
    let name: String
    let exercises: [(exerciseName: String, sets: Int, reps: Int)]
}

enum RoutineGenerator {
    /// Generate a workout routine based on goal, duration, and available equipment
    static func generate(
        goal: WorkoutGoal,
        duration: WorkoutDuration,
        availableEquipment: Set<Equipment>,
        allExercises: [Exercise]
    ) -> GeneratedRoutine {
        let targetGroups = goal.targetGroups
        let maxExercises = duration.exerciseCount

        // Filter exercises by equipment availability
        let available = allExercises.filter { exercise in
            targetGroups.contains(exercise.muscleGroup) &&
            ExerciseEquipmentMap.canPerform(exercise.name, with: availableEquipment)
        }

        // Group by muscle group
        var byGroup: [MuscleGroup: [Exercise]] = [:]
        for exercise in available {
            byGroup[exercise.muscleGroup, default: []].append(exercise)
        }

        // Selection strategy:
        // 1. Prioritize compound movements first (exercises needing barbell/dumbbell)
        // 2. Then isolation movements
        // 3. Distribute evenly across target muscle groups

        var selected: [(exercise: Exercise, sets: Int, reps: Int)] = []

        // Calculate exercises per group
        let groupCount = targetGroups.filter { byGroup[$0]?.isEmpty == false }.count
        guard groupCount > 0 else {
            return GeneratedRoutine(name: "\(goal.rawValue)", exercises: [])
        }

        let perGroup = max(1, maxExercises / groupCount)
        var remaining = maxExercises

        for group in targetGroups {
            guard let exercises = byGroup[group], !exercises.isEmpty else { continue }
            let count = min(perGroup, exercises.count, remaining)
            guard count > 0 else { continue }

            // Sort: compound first (more equipment = more compound-like), then shuffle for variety
            let sorted = exercises.shuffled().sorted {
                ExerciseEquipmentMap.equipment(for: $0.name).count >
                ExerciseEquipmentMap.equipment(for: $1.name).count
            }

            for i in 0..<count {
                let exercise = sorted[i]
                let (sets, reps) = setsAndReps(for: exercise, isFirst: i == 0)
                selected.append((exercise, sets, reps))
                remaining -= 1
            }
        }

        // Fill remaining slots with exercises from underrepresented groups
        if remaining > 0 {
            let usedNames = Set(selected.map(\.exercise.name))
            let unused = available.filter { !usedNames.contains($0.name) }.shuffled()
            for exercise in unused.prefix(remaining) {
                let (sets, reps) = setsAndReps(for: exercise, isFirst: false)
                selected.append((exercise, sets, reps))
            }
        }

        // Sort by target muscle group order for logical flow
        let groupOrder = targetGroups
        let sorted = selected.sorted { a, b in
            let aIdx = groupOrder.firstIndex(of: a.exercise.muscleGroup) ?? groupOrder.count
            let bIdx = groupOrder.firstIndex(of: b.exercise.muscleGroup) ?? groupOrder.count
            return aIdx < bIdx
        }

        return GeneratedRoutine(
            name: goal.rawValue,
            exercises: sorted.map { ($0.exercise.name, $0.sets, $0.reps) }
        )
    }

    /// Determine sets and reps based on exercise type
    private static func setsAndReps(for exercise: Exercise, isFirst: Bool) -> (Int, Int) {
        let equipment = ExerciseEquipmentMap.equipment(for: exercise.name)
        let isCompound = equipment.contains(.barbell) || equipment.count >= 2

        if isCompound && isFirst {
            // Main compound: heavy
            return (4, 6)
        } else if isCompound {
            // Secondary compound
            return (3, 8)
        } else {
            // Isolation
            return (3, 12)
        }
    }
}
