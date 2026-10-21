import Foundation

/// Точка графика динамики: один день.
public struct DayPoint: Hashable, Sendable {
    public var day: DayKey
    public var averageBefore: Double
    public var levels: [Int]

    public init(day: DayKey, averageBefore: Double, levels: [Int]) {
        self.day = day
        self.averageBefore = averageBefore
        self.levels = levels
    }
}

/// Насколько способ снижает тревогу у этого человека.
public struct MethodStat: Hashable, Sendable {
    public static let lowDataThreshold = 3

    public var method: CopingMethod
    public var count: Int
    public var averageDelta: Double
    public var isLowData: Bool { count < MethodStat.lowDataThreshold }

    public init(method: CopingMethod, count: Int, averageDelta: Double) {
        self.method = method
        self.count = count
        self.averageDelta = averageDelta
    }
}

/// Итог оглядки за период.
public struct FearSummary: Hashable, Sendable {
    public var feared: Int
    public var happened: Int
    public var happenedTolerable: Int
    public var answered: Int

    public init(feared: Int, happened: Int, happenedTolerable: Int, answered: Int) {
        self.feared = feared
        self.happened = happened
        self.happenedTolerable = happenedTolerable
        self.answered = answered
    }
}

public struct TriggerStat: Hashable, Sendable {
    public var trigger: String
    public var count: Int
    public var averageBefore: Double

    public init(trigger: String, count: Int, averageBefore: Double) {
        self.trigger = trigger
        self.count = count
        self.averageBefore = averageBefore
    }
}

/// Чистые расчёты для экрана «Итоги». Пустой вход даёт пустой выход.
public enum Stats {
    /// Средний уровень «до» по дням, по возрастанию дня.
    public static func trend(_ entries: [Entry], period: Period, now: Date, calendar: Calendar = .current) -> [DayPoint] {
        let grouped = Dictionary(grouping: entries.filter { period.contains($0.createdAt, now: now) }) { DayKey($0.createdAt, calendar: calendar) }
        return grouped.keys.sorted().map { day in
            let levels = grouped[day]!.map(\.levelBefore.value)
            return DayPoint(day: day, averageBefore: average(levels.map(Double.init)), levels: levels)
        }
    }

    /// Скользящее среднее по последним `window` точкам (включая текущую).
    public static func smoothed(_ points: [DayPoint], window: Int = 7) -> [Double] {
        let w = max(1, window)
        return points.indices.map { i in
            let slice = points[max(0, i - w + 1)...i].map(\.averageBefore)
            return average(slice)
        }
    }

    /// Способы с замером «после»: сильнее снижение первым, «мало данных» в конце.
    public static func methods(_ entries: [Entry], period: Period, now: Date) -> [MethodStat] {
        var deltas: [CopingMethod: [Int]] = [:]
        for e in entries where period.contains(e.createdAt, now: now) {
            guard let coping = e.coping, let delta = e.delta else { continue }
            deltas[coping, default: []].append(delta)
        }
        return deltas
            .map { MethodStat(method: $0.key, count: $0.value.count, averageDelta: average($0.value.map(Double.init))) }
            .sorted { a, b in
                if a.isLowData != b.isLowData { return !a.isLowData }
                if a.averageDelta != b.averageDelta { return a.averageDelta < b.averageDelta }
                return a.method.displayName < b.method.displayName
            }
    }

    /// Сколько страхов записано, сколько сбылось (по отвеченным вопросам).
    public static func fears(_ checks: [FearCheck], entries: [Entry], period: Period, now: Date) -> FearSummary {
        let inPeriod = entries.filter { $0.hasFear && period.contains($0.createdAt, now: now) }
        let ids = Set(inPeriod.map(\.id))
        var happened = 0, tolerable = 0, answered = 0
        for id in ids {
            let answers = checks
                .filter { $0.entryID == id && $0.outcome != nil && $0.outcome != .skipped }
                .sorted { ($0.answeredAt ?? .distantPast) < ($1.answeredAt ?? .distantPast) }
            guard let last = answers.last?.outcome else { continue }
            answered += 1
            if last == .happenedTolerable { happened += 1; tolerable += 1 }
            if last == .happenedBad { happened += 1 }
        }
        return FearSummary(feared: inPeriod.count, happened: happened, happenedTolerable: tolerable, answered: answered)
    }

    /// Частота и средний уровень по триггерам, частые первыми.
    public static func triggers(_ entries: [Entry], period: Period, now: Date) -> [TriggerStat] {
        var levels: [String: [Int]] = [:]
        for e in entries where period.contains(e.createdAt, now: now) {
            guard let t = e.trigger, !t.isEmpty else { continue }
            levels[t, default: []].append(e.levelBefore.value)
        }
        return levels
            .map { TriggerStat(trigger: $0.key, count: $0.value.count, averageBefore: average($0.value.map(Double.init))) }
            .sorted { a, b in a.count != b.count ? a.count > b.count : a.trigger < b.trigger }
    }

    static func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}
