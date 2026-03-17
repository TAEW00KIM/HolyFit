import Foundation

struct BuiltInTemplate: Identifiable {
    let id = UUID()
    let name: String
    let exercises: [(exerciseName: String, sets: Int, reps: Int)]
}

enum BuiltInTemplates {
    static let all: [BuiltInTemplate] = [
        BuiltInTemplate(
            name: "5x5 스트렝스",
            exercises: [
                (exerciseName: "스쿼트", sets: 5, reps: 5),
                (exerciseName: "벤치프레스", sets: 5, reps: 5),
                (exerciseName: "바벨 로우", sets: 5, reps: 5),
            ]
        ),
        BuiltInTemplate(
            name: "PPL - 밀기",
            exercises: [
                (exerciseName: "벤치프레스", sets: 4, reps: 8),
                (exerciseName: "인클라인 덤벨프레스", sets: 3, reps: 10),
                (exerciseName: "덤벨 숄더 프레스", sets: 3, reps: 10),
                (exerciseName: "트라이셉 푸시다운", sets: 3, reps: 12),
                (exerciseName: "케이블 크로스오버", sets: 3, reps: 12),
            ]
        ),
        BuiltInTemplate(
            name: "PPL - 당기기",
            exercises: [
                (exerciseName: "데드리프트", sets: 3, reps: 5),
                (exerciseName: "바벨 로우", sets: 4, reps: 8),
                (exerciseName: "랫풀다운", sets: 3, reps: 10),
                (exerciseName: "케이블 컬", sets: 3, reps: 12),
                (exerciseName: "페이스풀", sets: 3, reps: 15),
            ]
        ),
        BuiltInTemplate(
            name: "PPL - 하체",
            exercises: [
                (exerciseName: "스쿼트", sets: 4, reps: 8),
                (exerciseName: "레그 프레스", sets: 3, reps: 10),
                (exerciseName: "레그 컬", sets: 3, reps: 12),
                (exerciseName: "레그 익스텐션", sets: 3, reps: 12),
                (exerciseName: "카프 레이즈", sets: 4, reps: 15),
            ]
        ),
        BuiltInTemplate(
            name: "상체 운동",
            exercises: [
                (exerciseName: "벤치프레스", sets: 4, reps: 8),
                (exerciseName: "바벨 로우", sets: 4, reps: 8),
                (exerciseName: "덤벨 숄더 프레스", sets: 3, reps: 10),
                (exerciseName: "덤벨 컬", sets: 3, reps: 12),
                (exerciseName: "트라이셉 푸시다운", sets: 3, reps: 12),
            ]
        ),
        BuiltInTemplate(
            name: "하체 운동",
            exercises: [
                (exerciseName: "스쿼트", sets: 4, reps: 8),
                (exerciseName: "루마니안 데드리프트", sets: 3, reps: 10),
                (exerciseName: "레그 프레스", sets: 3, reps: 10),
                (exerciseName: "레그 컬", sets: 3, reps: 12),
                (exerciseName: "힙 쓰러스트", sets: 3, reps: 10),
            ]
        ),
    ]
}
