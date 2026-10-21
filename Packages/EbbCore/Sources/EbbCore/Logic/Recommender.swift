import Foundation

/// Что приложение предлагает сделать после замера.
public enum Suggestion: Hashable, Sendable {
    case practice(PracticeKind)
    case justRecord

    public var title: String {
        switch self {
        case .practice(let kind): kind.title
        case .justRecord: "Просто записать"
        }
    }
}

public struct Recommendation: Hashable, Sendable {
    public var primary: Suggestion
    public var fallback: Suggestion
    public var offerDefer: Bool

    public init(primary: Suggestion, fallback: Suggestion, offerDefer: Bool) {
        self.primary = primary
        self.fallback = fallback
        self.offerDefer = offerDefer
    }
}

/// Детерминированное правило рекомендации (§6 спецификации).
public enum Recommender {
    public static func recommend(level: AnxietyLevel, hasThought: Bool, hasFear: Bool, at date: Date, calendar: Calendar = .current) -> Recommendation {
        var primary: Suggestion
        var fallback: Suggestion
        switch (level.value, hasThought) {
        case (7..., _):
            primary = .practice(.breathing); fallback = .practice(.grounding)
        case (4...6, true):
            primary = .practice(.thoughtCheck); fallback = .practice(.breathing)
        case (4...6, false):
            primary = .practice(.breathing); fallback = .practice(.grounding)
        case (_, true):
            primary = .practice(.deferThought); fallback = .practice(.thoughtCheck)
        case (_, false):
            primary = .justRecord; fallback = .practice(.breathing)
        }
        if isNight(date, calendar: calendar) {
            fallback = .practice(.muscleRelaxation)
        }
        return Recommendation(primary: primary, fallback: fallback, offerDefer: hasFear)
    }

    /// 22:00–06:00 по локальному времени.
    static func isNight(_ date: Date, calendar: Calendar) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour >= 22 || hour < 6
    }
}
