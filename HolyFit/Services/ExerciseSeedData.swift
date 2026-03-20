import Foundation
import SwiftData

struct ExerciseSeedData {
    /// Returns true if seeding succeeded, false otherwise
    @discardableResult
    static func seed(into context: ModelContext) -> Bool {
        let exercises = allExercises()
        for exercise in exercises {
            context.insert(exercise)
        }
        do {
            try context.save()
            return true
        } catch {
            // Rollback inserted exercises on failure
            for exercise in exercises {
                context.delete(exercise)
            }
            return false
        }
    }

    static func allExercises() -> [Exercise] {
        var list: [Exercise] = []

        // 가슴
        list.append(contentsOf: [
            Exercise(name: "벤치프레스", muscleGroup: .chest, instructions: "바벨을 가슴까지 내렸다 올리기"),
            Exercise(name: "인클라인 벤치프레스", muscleGroup: .chest, instructions: "30도 경사에서 바벨 프레스"),
            Exercise(name: "디클라인 벤치프레스", muscleGroup: .chest, instructions: "하향 경사에서 바벨 프레스"),
            Exercise(name: "덤벨 벤치프레스", muscleGroup: .chest, instructions: "덤벨로 플랫 벤치 프레스"),
            Exercise(name: "인클라인 덤벨프레스", muscleGroup: .chest, instructions: "경사 벤치에서 덤벨 프레스"),
            Exercise(name: "덤벨 플라이", muscleGroup: .chest, instructions: "팔을 벌리며 가슴 스트레칭"),
            Exercise(name: "인클라인 덤벨 플라이", muscleGroup: .chest, instructions: "경사 벤치에서 덤벨 플라이"),
            Exercise(name: "케이블 크로스오버", muscleGroup: .chest, instructions: "케이블을 교차하며 가슴 수축"),
            Exercise(name: "로우 케이블 크로스오버", muscleGroup: .chest, instructions: "아래에서 위로 케이블 교차"),
            Exercise(name: "머신 체스트 프레스", muscleGroup: .chest, instructions: "머신으로 가슴 프레스"),
            Exercise(name: "인클라인 머신 프레스", muscleGroup: .chest, instructions: "경사 머신 프레스"),
            Exercise(name: "스미스 머신 벤치프레스", muscleGroup: .chest, instructions: "스미스 머신으로 벤치프레스"),
            Exercise(name: "스미스 인클라인 프레스", muscleGroup: .chest, instructions: "스미스 머신 경사 프레스"),
            Exercise(name: "펙덱 플라이", muscleGroup: .chest, instructions: "펙덱 머신으로 가슴 수축"),
            Exercise(name: "딥스", muscleGroup: .chest, instructions: "평행봉에서 상체를 앞으로 기울여 수행"),
            Exercise(name: "어시스트 딥스", muscleGroup: .chest, instructions: "어시스트 머신으로 딥스"),
            Exercise(name: "푸시업", muscleGroup: .chest, instructions: "팔굽혀펴기"),
            Exercise(name: "와이드 그립 벤치프레스", muscleGroup: .chest, instructions: "넓은 그립으로 벤치프레스"),
            Exercise(name: "클로즈그립 덤벨프레스", muscleGroup: .chest, instructions: "좁은 그립으로 덤벨 프레스"),
            Exercise(name: "디클라인 덤벨프레스", muscleGroup: .chest, instructions: "하향 경사에서 덤벨 프레스"),
            Exercise(name: "디클라인 덤벨 플라이", muscleGroup: .chest, instructions: "하향 경사에서 덤벨 플라이"),
            Exercise(name: "하이 케이블 크로스오버", muscleGroup: .chest, instructions: "위에서 아래로 케이블 교차"),
            Exercise(name: "인클라인 스미스 프레스", muscleGroup: .chest, instructions: "스미스 머신 경사 프레스"),
            Exercise(name: "머신 플라이", muscleGroup: .chest, instructions: "머신으로 플라이 동작"),
            Exercise(name: "원암 덤벨 벤치프레스", muscleGroup: .chest, instructions: "한 팔씩 덤벨 벤치프레스"),
            Exercise(name: "원암 케이블 플라이", muscleGroup: .chest, instructions: "한 팔씩 케이블 플라이"),
        ])

        // 등
        list.append(contentsOf: [
            Exercise(name: "데드리프트", muscleGroup: .back, instructions: "바벨을 바닥에서 들어올리기"),
            Exercise(name: "컨벤셔널 데드리프트", muscleGroup: .back, instructions: "일반 스탠스 데드리프트"),
            Exercise(name: "스모 데드리프트", muscleGroup: .back, instructions: "넓은 스탠스 데드리프트"),
            Exercise(name: "바벨 로우", muscleGroup: .back, instructions: "상체를 숙이고 바벨 당기기"),
            Exercise(name: "덤벨 로우", muscleGroup: .back, instructions: "한 팔씩 덤벨 당기기"),
            Exercise(name: "랫풀다운", muscleGroup: .back, instructions: "케이블을 가슴 쪽으로 당기기"),
            Exercise(name: "클로즈그립 랫풀다운", muscleGroup: .back, instructions: "좁은 그립으로 랫풀다운"),
            Exercise(name: "시티드 로우", muscleGroup: .back, instructions: "앉아서 케이블 당기기"),
            Exercise(name: "풀업", muscleGroup: .back, instructions: "턱걸이"),
            Exercise(name: "어시스트 풀업", muscleGroup: .back, instructions: "어시스트 머신으로 풀업"),
            Exercise(name: "친업", muscleGroup: .back, instructions: "언더그립 턱걸이"),
            Exercise(name: "케이블 로우", muscleGroup: .back, instructions: "케이블로 로우"),
            Exercise(name: "티바 로우", muscleGroup: .back, instructions: "T바를 이용한 로우"),
            Exercise(name: "펜들레이 로우", muscleGroup: .back, instructions: "바닥에서 시작하는 바벨 로우"),
            Exercise(name: "머신 로우", muscleGroup: .back, instructions: "머신으로 로우"),
            Exercise(name: "케이블 풀오버", muscleGroup: .back, instructions: "케이블로 풀오버"),
            Exercise(name: "스미스 머신 로우", muscleGroup: .back, instructions: "스미스 머신으로 바벨 로우"),
            Exercise(name: "와이드 그립 랫풀다운", muscleGroup: .back, instructions: "넓은 그립으로 랫풀다운"),
            Exercise(name: "리버스 그립 랫풀다운", muscleGroup: .back, instructions: "언더그립으로 랫풀다운"),
            Exercise(name: "뉴트럴 그립 랫풀다운", muscleGroup: .back, instructions: "중립 그립으로 랫풀다운"),
            Exercise(name: "와이드 그립 시티드 로우", muscleGroup: .back, instructions: "넓은 그립으로 시티드 로우"),
            Exercise(name: "클로즈그립 시티드 로우", muscleGroup: .back, instructions: "좁은 그립으로 시티드 로우"),
            Exercise(name: "리버스 그립 바벨 로우", muscleGroup: .back, instructions: "언더그립으로 바벨 로우"),
            Exercise(name: "와이드 그립 풀업", muscleGroup: .back, instructions: "넓은 그립으로 풀업"),
            Exercise(name: "뉴트럴 그립 풀업", muscleGroup: .back, instructions: "중립 그립으로 풀업"),
            Exercise(name: "원암 덤벨 로우", muscleGroup: .back, instructions: "한 손으로 덤벨 로우"),
            Exercise(name: "씰 로우", muscleGroup: .back, instructions: "벤치에 엎드려 바벨/덤벨 로우"),
            Exercise(name: "체스트 서포트 로우", muscleGroup: .back, instructions: "가슴 받침대에서 로우"),
            Exercise(name: "메도우즈 로우", muscleGroup: .back, instructions: "랜드마인 한 팔 로우"),
            Exercise(name: "원암 케이블 로우", muscleGroup: .back, instructions: "한 팔씩 케이블 로우"),
            Exercise(name: "원암 랫풀다운", muscleGroup: .back, instructions: "한 팔씩 랫풀다운"),
        ])

        // 어깨
        list.append(contentsOf: [
            Exercise(name: "오버헤드 프레스", muscleGroup: .shoulders, instructions: "바벨을 머리 위로 밀기"),
            Exercise(name: "덤벨 숄더 프레스", muscleGroup: .shoulders, instructions: "덤벨로 숄더 프레스"),
            Exercise(name: "머신 숄더 프레스", muscleGroup: .shoulders, instructions: "머신으로 숄더 프레스"),
            Exercise(name: "스미스 머신 숄더 프레스", muscleGroup: .shoulders, instructions: "스미스 머신으로 숄더 프레스"),
            Exercise(name: "아놀드 프레스", muscleGroup: .shoulders, instructions: "회전하며 프레스"),
            Exercise(name: "사이드 레터럴 레이즈", muscleGroup: .shoulders, instructions: "덤벨을 옆으로 들어올리기"),
            Exercise(name: "케이블 사이드 레이즈", muscleGroup: .shoulders, instructions: "케이블로 옆으로 들어올리기"),
            Exercise(name: "머신 사이드 레이즈", muscleGroup: .shoulders, instructions: "머신으로 사이드 레이즈"),
            Exercise(name: "프론트 레이즈", muscleGroup: .shoulders, instructions: "덤벨을 앞으로 들어올리기"),
            Exercise(name: "페이스풀", muscleGroup: .shoulders, instructions: "케이블을 얼굴 쪽으로 당기기"),
            Exercise(name: "리어 델트 플라이", muscleGroup: .shoulders, instructions: "후면 삼각근 플라이"),
            Exercise(name: "리어 델트 머신", muscleGroup: .shoulders, instructions: "머신으로 후면 삼각근"),
            Exercise(name: "업라이트 로우", muscleGroup: .shoulders, instructions: "바벨을 턱까지 당기기"),
            Exercise(name: "슈러그", muscleGroup: .shoulders, instructions: "바벨/덤벨로 어깨 으쓱"),
            Exercise(name: "덤벨 사이드 레이즈", muscleGroup: .shoulders, instructions: "덤벨로 옆으로 들어올리기"),
            Exercise(name: "벤트오버 리어 델트 레이즈", muscleGroup: .shoulders, instructions: "상체 숙이고 후면 삼각근 레이즈"),
            Exercise(name: "케이블 리어 델트 플라이", muscleGroup: .shoulders, instructions: "케이블로 후면 삼각근 플라이"),
            Exercise(name: "바벨 프론트 레이즈", muscleGroup: .shoulders, instructions: "바벨로 앞으로 들어올리기"),
            Exercise(name: "랜드마인 프레스", muscleGroup: .shoulders, instructions: "랜드마인으로 숄더 프레스"),
            Exercise(name: "원암 덤벨 숄더 프레스", muscleGroup: .shoulders, instructions: "한 팔씩 덤벨 숄더 프레스"),
            Exercise(name: "원암 사이드 레이즈", muscleGroup: .shoulders, instructions: "한 팔씩 사이드 레이즈"),
            Exercise(name: "원암 케이블 프론트 레이즈", muscleGroup: .shoulders, instructions: "한 팔씩 케이블 프론트 레이즈"),
        ])

        // 하체
        list.append(contentsOf: [
            Exercise(name: "스쿼트", muscleGroup: .legs, instructions: "바벨을 메고 앉았다 일어서기"),
            Exercise(name: "프론트 스쿼트", muscleGroup: .legs, instructions: "바벨을 앞에 메고 스쿼트"),
            Exercise(name: "스미스 머신 스쿼트", muscleGroup: .legs, instructions: "스미스 머신으로 스쿼트"),
            Exercise(name: "핵 스쿼트", muscleGroup: .legs, instructions: "핵 스쿼트 머신"),
            Exercise(name: "레그 프레스", muscleGroup: .legs, instructions: "머신으로 다리 밀기"),
            Exercise(name: "레그 익스텐션", muscleGroup: .legs, instructions: "앉아서 다리 펴기"),
            Exercise(name: "레그 컬", muscleGroup: .legs, instructions: "엎드려서 다리 굽히기"),
            Exercise(name: "시티드 레그 컬", muscleGroup: .legs, instructions: "앉아서 다리 굽히기"),
            Exercise(name: "루마니안 데드리프트", muscleGroup: .legs, instructions: "다리를 살짝 굽히고 데드리프트"),
            Exercise(name: "불가리안 스플릿 스쿼트", muscleGroup: .legs, instructions: "한 발을 벤치에 올리고 스쿼트"),
            Exercise(name: "힙 쓰러스트", muscleGroup: .legs, instructions: "등을 벤치에 대고 힙 들기"),
            Exercise(name: "머신 힙 쓰러스트", muscleGroup: .legs, instructions: "머신으로 힙 쓰러스트"),
            Exercise(name: "카프 레이즈", muscleGroup: .legs, instructions: "종아리 들어올리기"),
            Exercise(name: "시티드 카프 레이즈", muscleGroup: .legs, instructions: "앉아서 종아리 들어올리기"),
            Exercise(name: "런지", muscleGroup: .legs, instructions: "한 발 앞으로 내딛으며 앉기"),
            Exercise(name: "워킹 런지", muscleGroup: .legs, instructions: "걸으며 런지"),
            Exercise(name: "고블릿 스쿼트", muscleGroup: .legs, instructions: "덤벨을 가슴에 안고 스쿼트"),
            Exercise(name: "힙 어브덕션", muscleGroup: .legs, instructions: "머신으로 다리 벌리기"),
            Exercise(name: "힙 어덕션", muscleGroup: .legs, instructions: "머신으로 다리 모으기"),
            Exercise(name: "글루트 킥백 머신", muscleGroup: .legs, instructions: "머신으로 글루트 킥백"),
            Exercise(name: "내로우 스탠스 스쿼트", muscleGroup: .legs, instructions: "좁은 스탠스로 스쿼트"),
            Exercise(name: "와이드 스탠스 스쿼트", muscleGroup: .legs, instructions: "넓은 스탠스로 스쿼트"),
            Exercise(name: "덤벨 런지", muscleGroup: .legs, instructions: "덤벨 들고 런지"),
            Exercise(name: "바벨 힙 쓰러스트", muscleGroup: .legs, instructions: "바벨로 힙 쓰러스트"),
            Exercise(name: "스티프 레그 데드리프트", muscleGroup: .legs, instructions: "다리 펴고 데드리프트"),
            Exercise(name: "덤벨 루마니안 데드리프트", muscleGroup: .legs, instructions: "덤벨로 루마니안 데드리프트"),
            Exercise(name: "싱글 레그 레그프레스", muscleGroup: .legs, instructions: "한 다리씩 레그프레스"),
            Exercise(name: "시시 스쿼트", muscleGroup: .legs, instructions: "뒤로 기울이며 스쿼트"),
            Exercise(name: "스텝업", muscleGroup: .legs, instructions: "박스 위로 올라서기"),
            Exercise(name: "원암 덤벨 런지", muscleGroup: .legs, instructions: "한 손에 덤벨 들고 런지"),
            Exercise(name: "싱글 레그 레그컬", muscleGroup: .legs, instructions: "한 다리씩 레그컬"),
            Exercise(name: "싱글 레그 레그 익스텐션", muscleGroup: .legs, instructions: "한 다리씩 레그 익스텐션"),
            Exercise(name: "싱글 레그 루마니안 데드리프트", muscleGroup: .legs, instructions: "한 다리로 루마니안 데드리프트"),
        ])

        // 이두
        list.append(contentsOf: [
            Exercise(name: "바벨 컬", muscleGroup: .biceps, instructions: "바벨로 팔 굽히기"),
            Exercise(name: "이지바 컬", muscleGroup: .biceps, instructions: "이지바로 팔 굽히기"),
            Exercise(name: "덤벨 컬", muscleGroup: .biceps, instructions: "덤벨로 팔 굽히기"),
            Exercise(name: "해머 컬", muscleGroup: .biceps, instructions: "중립 그립으로 덤벨 컬"),
            Exercise(name: "프리처 컬", muscleGroup: .biceps, instructions: "프리처 벤치에서 컬"),
            Exercise(name: "머신 프리처 컬", muscleGroup: .biceps, instructions: "머신으로 프리처 컬"),
            Exercise(name: "인클라인 덤벨 컬", muscleGroup: .biceps, instructions: "경사 벤치에서 덤벨 컬"),
            Exercise(name: "컨센트레이션 컬", muscleGroup: .biceps, instructions: "앉아서 한 팔씩 집중 컬"),
            Exercise(name: "케이블 컬", muscleGroup: .biceps, instructions: "케이블로 팔 굽히기"),
            Exercise(name: "로프 해머 컬", muscleGroup: .biceps, instructions: "케이블 로프로 해머 컬"),
            Exercise(name: "스파이더 컬", muscleGroup: .biceps, instructions: "인클라인 벤치에 엎드려 컬"),
            Exercise(name: "리버스 컬", muscleGroup: .biceps, instructions: "오버그립으로 바벨/덤벨 컬"),
            Exercise(name: "와이드 그립 바벨 컬", muscleGroup: .biceps, instructions: "넓은 그립으로 바벨 컬"),
            Exercise(name: "내로우 그립 바벨 컬", muscleGroup: .biceps, instructions: "좁은 그립으로 바벨 컬"),
            Exercise(name: "크로스바디 해머 컬", muscleGroup: .biceps, instructions: "몸 가로질러 해머 컬"),
            Exercise(name: "21s 컬", muscleGroup: .biceps, instructions: "하/상/풀 각 7회 바벨 컬"),
            Exercise(name: "케이블 해머 컬", muscleGroup: .biceps, instructions: "로프로 해머 컬"),
            Exercise(name: "원암 케이블 컬", muscleGroup: .biceps, instructions: "한 팔씩 케이블 컬"),
            Exercise(name: "원암 프리처 컬", muscleGroup: .biceps, instructions: "한 팔씩 프리처 컬"),
        ])

        // 삼두
        list.append(contentsOf: [
            Exercise(name: "트라이셉 푸시다운", muscleGroup: .triceps, instructions: "케이블을 아래로 밀기"),
            Exercise(name: "로프 푸시다운", muscleGroup: .triceps, instructions: "로프 어태치먼트로 푸시다운"),
            Exercise(name: "오버헤드 트라이셉 익스텐션", muscleGroup: .triceps, instructions: "머리 위에서 팔 펴기"),
            Exercise(name: "케이블 오버헤드 익스텐션", muscleGroup: .triceps, instructions: "케이블로 머리 위 삼두 익스텐션"),
            Exercise(name: "스컬 크러셔", muscleGroup: .triceps, instructions: "바벨을 이마 쪽으로 내렸다 올리기"),
            Exercise(name: "클로즈그립 벤치프레스", muscleGroup: .triceps, instructions: "좁은 그립으로 벤치프레스"),
            Exercise(name: "삼두 딥스", muscleGroup: .triceps, instructions: "평행봉에서 팔 펴기"),
            Exercise(name: "머신 딥스", muscleGroup: .triceps, instructions: "머신으로 삼두 딥스"),
            Exercise(name: "킥백", muscleGroup: .triceps, instructions: "덤벨을 뒤로 밀기"),
            Exercise(name: "덤벨 오버헤드 익스텐션", muscleGroup: .triceps, instructions: "덤벨로 머리 위 삼두 펴기"),
            Exercise(name: "리버스 그립 푸시다운", muscleGroup: .triceps, instructions: "언더그립으로 푸시다운"),
            Exercise(name: "V바 푸시다운", muscleGroup: .triceps, instructions: "V바 어태치먼트로 푸시다운"),
            Exercise(name: "원암 케이블 푸시다운", muscleGroup: .triceps, instructions: "한 팔씩 케이블 푸시다운"),
            Exercise(name: "다이아몬드 푸시업", muscleGroup: .triceps, instructions: "손 모아 팔굽혀펴기"),
            Exercise(name: "벤치 딥스", muscleGroup: .triceps, instructions: "벤치에 손 짚고 딥스"),
            Exercise(name: "원암 덤벨 오버헤드 익스텐션", muscleGroup: .triceps, instructions: "한 팔씩 머리 위 삼두 펴기"),
            Exercise(name: "원암 케이블 킥백", muscleGroup: .triceps, instructions: "한 팔씩 케이블 킥백"),
        ])

        // 코어
        list.append(contentsOf: [
            Exercise(name: "플랭크", muscleGroup: .core, instructions: "엎드려 팔꿈치 지지 자세 유지"),
            Exercise(name: "크런치", muscleGroup: .core, instructions: "누워서 상체 들기"),
            Exercise(name: "머신 크런치", muscleGroup: .core, instructions: "머신으로 복근 크런치"),
            Exercise(name: "케이블 크런치", muscleGroup: .core, instructions: "케이블로 무릎 꿇고 크런치"),
            Exercise(name: "레그 레이즈", muscleGroup: .core, instructions: "누워서 다리 들기"),
            Exercise(name: "러시안 트위스트", muscleGroup: .core, instructions: "앉아서 상체 회전"),
            Exercise(name: "행잉 레그 레이즈", muscleGroup: .core, instructions: "매달려서 다리 들기"),
            Exercise(name: "행잉 니 레이즈", muscleGroup: .core, instructions: "매달려서 무릎 들기"),
            Exercise(name: "앱 롤아웃", muscleGroup: .core, instructions: "ab 롤러로 몸 펴기"),
            Exercise(name: "사이드 플랭크", muscleGroup: .core, instructions: "옆으로 누워 몸 지지"),
            Exercise(name: "우드찹", muscleGroup: .core, instructions: "케이블로 대각선 회전"),
        ])

        // 전신
        list.append(contentsOf: [
            Exercise(name: "버피", muscleGroup: .fullBody, instructions: "스쿼트-플랭크-점프 반복"),
            Exercise(name: "터키쉬 겟업", muscleGroup: .fullBody, instructions: "누운 상태에서 일어서기"),
            Exercise(name: "케틀벨 스윙", muscleGroup: .fullBody, instructions: "케틀벨을 힙 힌지로 스윙"),
            Exercise(name: "클린 앤 프레스", muscleGroup: .fullBody, instructions: "바벨을 바닥에서 머리 위로"),
            Exercise(name: "맨 메이커", muscleGroup: .fullBody, instructions: "덤벨 버피 + 로우 + 프레스"),
            Exercise(name: "파머스 워크", muscleGroup: .fullBody, instructions: "무거운 덤벨 들고 걷기"),
        ])

        // 유산소
        list.append(contentsOf: [
            Exercise(name: "러닝", muscleGroup: .cardio, instructions: "트레드밀 또는 야외 달리기"),
            Exercise(name: "사이클", muscleGroup: .cardio, instructions: "실내 자전거"),
            Exercise(name: "로잉머신", muscleGroup: .cardio, instructions: "노젓기 머신"),
            Exercise(name: "줄넘기", muscleGroup: .cardio, instructions: "줄넘기"),
            Exercise(name: "스프린트 인터벌", muscleGroup: .cardio, instructions: "전력 질주와 휴식 반복"),
            Exercise(name: "스텝퍼", muscleGroup: .cardio, instructions: "계단 오르기 머신"),
        ])

        return list
    }
}
