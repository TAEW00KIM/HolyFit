import Foundation
import SwiftData

@Observable
class StatsViewModel {
    var selectedExercise: Exercise?
    var dateRange: DateRange = .threeMonths

    enum DateRange: String, CaseIterable, Identifiable {
        case oneWeek = "1주"
        case oneMonth = "1달"
        case threeMonths = "3달"
        case sixMonths = "6달"
        case oneYear = "1년"
        case all = "전체"

        var id: String { rawValue }

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .oneWeek: return calendar.date(byAdding: .weekOfYear, value: -1, to: Date())
            case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: Date())
            case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
            case .oneYear: return calendar.date(byAdding: .year, value: -1, to: Date())
            case .all: return nil
            }
        }
    }

    struct WeightDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
    }

    struct VolumeDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let totalVolume: Double
    }

    struct OneRepMaxDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let estimatedMax: Double
    }

    // 운동별 세션 최대 중량 추이
    func weightProgression(for exercise: Exercise, sessions: [WorkoutSession]) -> [WeightDataPoint] {
        let filtered = filteredSessions(sessions)
        var dataPoints: [WeightDataPoint] = []

        for session in filtered {
            let entries = session.entries.filter { $0.exercise?.id == exercise.id }
            for entry in entries {
                if let maxWeight = entry.sets.map(\.weight).max(), maxWeight > 0 {
                    dataPoints.append(WeightDataPoint(date: session.startDate, maxWeight: maxWeight))
                }
            }
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    // 세션별 총 볼륨 추이
    func volumeProgression(sessions: [WorkoutSession]) -> [VolumeDataPoint] {
        let filtered = filteredSessions(sessions)
        return filtered
            .filter { $0.totalVolume > 0 }
            .map { VolumeDataPoint(date: $0.startDate, totalVolume: $0.totalVolume) }
            .sorted { $0.date < $1.date }
    }

    // 운동별 1RM 추정 추이 (Epley 공식)
    func oneRepMaxProgression(for exercise: Exercise, sessions: [WorkoutSession]) -> [OneRepMaxDataPoint] {
        let filtered = filteredSessions(sessions)
        var dataPoints: [OneRepMaxDataPoint] = []

        for session in filtered {
            let entries = session.entries.filter { $0.exercise?.id == exercise.id }
            for entry in entries {
                if let bestSet = entry.sets.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }),
                   bestSet.estimatedOneRepMax > 0 {
                    dataPoints.append(OneRepMaxDataPoint(date: session.startDate, estimatedMax: bestSet.estimatedOneRepMax))
                }
            }
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    // 운동별 통계 요약
    func exerciseStats(for exercise: Exercise, sessions: [WorkoutSession]) -> ExerciseStatsSummary {
        let filtered = filteredSessions(sessions)
        var allSets: [WorkoutSet] = []
        var sessionCount = 0

        for session in filtered {
            let entries = session.entries.filter { $0.exercise?.id == exercise.id }
            if !entries.isEmpty {
                sessionCount += 1
                for entry in entries {
                    allSets.append(contentsOf: entry.sets)
                }
            }
        }

        let prWeight = allSets.map(\.weight).max() ?? 0
        let prVolume = allSets.map(\.volume).max() ?? 0
        let pr1RM = allSets.map(\.estimatedOneRepMax).max() ?? 0

        return ExerciseStatsSummary(
            totalSessions: sessionCount,
            totalSets: allSets.count,
            prWeight: prWeight,
            prVolume: prVolume,
            estimated1RM: pr1RM
        )
    }

    private func filteredSessions(_ sessions: [WorkoutSession]) -> [WorkoutSession] {
        guard let startDate = dateRange.startDate else { return sessions }
        return sessions.filter { $0.startDate >= startDate }
    }
}

struct ExerciseStatsSummary {
    let totalSessions: Int
    let totalSets: Int
    let prWeight: Double
    let prVolume: Double
    let estimated1RM: Double
}
