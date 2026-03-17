import Foundation

enum AppDateFormatter {
    static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일"
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f
    }()

    static let dayNumber: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "d"
        return f
    }()

    static let monthShort: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월"
        return f
    }()

    static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "EEEE"
        return f
    }()

    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f
    }()

    static let chartDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d"
        return f
    }()

    static func durationString(from interval: TimeInterval) -> String {
        let totalMinutes = Int(round(interval / 60))
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let remainMinutes = totalMinutes % 60
            return remainMinutes > 0 ? "\(hours)시간 \(remainMinutes)분" : "\(hours)시간"
        }
        return "\(max(1, totalMinutes))분"
    }
}
