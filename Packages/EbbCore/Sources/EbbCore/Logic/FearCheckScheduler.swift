import Foundation

/// Планирует вопросы оглядки для записи со страхом и гасит их по ответу.
public enum FearCheckScheduler {
    public static let day3Interval: TimeInterval = 3 * 86400
    public static let day14Interval: TimeInterval = 14 * 86400

    /// Два вопроса (3 и 14 дней от записи) или ничего, если страх не записан.
    public static func checks(for entry: Entry) -> [FearCheck] {
        guard entry.hasFear else { return [] }
        return [
            FearCheck(entryID: entry.id, stage: .day3, dueAt: entry.createdAt.addingTimeInterval(day3Interval)),
            FearCheck(entryID: entry.id, stage: .day14, dueAt: entry.createdAt.addingTimeInterval(day14Interval)),
        ]
    }

    /// Неотвеченные вопросы, срок которых наступил. Ранние первыми.
    public static func due(_ checks: [FearCheck], now: Date) -> [FearCheck] {
        checks.filter { !$0.isAnswered && $0.dueAt <= now }.sorted { $0.dueAt < $1.dueAt }
    }

    /// Записывает ответ. «Случилось» на 3-й день снимает вопрос 14-го дня той же записи.
    public static func answer(_ check: FearCheck, outcome: FearCheck.Outcome, in checks: [FearCheck], at date: Date) -> [FearCheck] {
        let happened = outcome == .happenedTolerable || outcome == .happenedBad
        return checks.compactMap { existing in
            if existing.id == check.id {
                var answered = existing
                answered.outcome = outcome
                answered.answeredAt = date
                return answered
            }
            if happened, check.stage == .day3, existing.entryID == check.entryID, existing.stage == .day14 {
                return nil
            }
            return existing
        }
    }
}
