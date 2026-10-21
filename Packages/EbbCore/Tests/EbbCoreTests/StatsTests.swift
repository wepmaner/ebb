import Foundation
import Testing
@testable import EbbCore

private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

@Test func emptyInputsGiveEmptyOutputs() {
    let now = Date()
    #expect(Stats.trend([], period: .days30, now: now).isEmpty)
    #expect(Stats.methods([], period: .all, now: now).isEmpty)
    #expect(Stats.triggers([], period: .all, now: now).isEmpty)
    #expect(Stats.smoothed([]).isEmpty)
    #expect(Stats.fears([], entries: [], period: .all, now: now) == FearSummary(feared: 0, happened: 0, happenedTolerable: 0, answered: 0))
}

@Test func methodsIgnoreEntriesWithoutAfterAndFlagLowData() {
    let now = Date()
    func e(_ m: CopingMethod, _ b: Int, _ a: Int?) -> Entry {
        Entry(createdAt: now, levelBefore: .init(clamping: b), coping: m, levelAfter: a.map { .init(clamping: $0) })
    }
    let es = [e(.practice(.breathing), 8, 4), e(.practice(.breathing), 7, 4), e(.practice(.breathing), 6, 3), e(.ownAction("игры"), 6, 5), e(.ownAction("игры"), 7, nil)]
    let m = Stats.methods(es, period: .all, now: now)
    #expect(m.count == 2)
    #expect(m[0].method == .practice(.breathing))
    #expect(abs(m[0].averageDelta + 3.333) < 0.01)
    #expect(m[0].count == 3)
    #expect(!m[0].isLowData)
    #expect(m[1].method == .ownAction("игры"))
    #expect(m[1].count == 1)
    #expect(m[1].isLowData)
}

@Test func trendAveragesSameDayAndRespectsPeriod() {
    let now = ISO8601DateFormatter().date(from: "2026-10-21T12:00:00Z")!
    let old = Entry(createdAt: now.addingTimeInterval(-40 * 86400), levelBefore: .init(clamping: 9))
    let a = Entry(createdAt: now.addingTimeInterval(-3600), levelBefore: .init(clamping: 8))
    let b = Entry(createdAt: now.addingTimeInterval(-7200), levelBefore: .init(clamping: 4))
    let t = Stats.trend([old, a, b], period: .days30, now: now, calendar: utc)
    #expect(t.count == 1)
    #expect(t[0].averageBefore == 6)
    #expect(t[0].levels.sorted() == [4, 8])
    let all = Stats.trend([old, a, b], period: .all, now: now, calendar: utc)
    #expect(all.count == 2)
    #expect(all[0].day < all[1].day)
}

@Test func smoothedUsesTrailingWindow() {
    let points = [1.0, 3.0, 5.0].enumerated().map { DayPoint(day: DayKey(raw: "2026-10-0\($0.offset + 1)"), averageBefore: $0.element, levels: []) }
    #expect(Stats.smoothed(points, window: 2) == [1.0, 2.0, 4.0])
}

@Test func fearSummaryCountsOnlyAnswered() {
    let e = Entry(createdAt: Date(timeIntervalSince1970: 0), levelBefore: .init(clamping: 5), fear: "x")
    var c = FearCheckScheduler.checks(for: e)
    c[0].answeredAt = Date()
    c[0].outcome = .happenedTolerable
    let s = Stats.fears(c, entries: [e], period: .all, now: Date())
    #expect(s == FearSummary(feared: 1, happened: 1, happenedTolerable: 1, answered: 1))
    let skippedOnly = FearCheckScheduler.answer(c[1], outcome: .skipped, in: FearCheckScheduler.checks(for: e), at: Date())
    #expect(Stats.fears(skippedOnly, entries: [e], period: .all, now: Date()).answered == 0)
}

@Test func triggersCountAndAverage() {
    let now = Date()
    let es = [
        Entry(createdAt: now, levelBefore: .init(clamping: 8), trigger: "общение"),
        Entry(createdAt: now, levelBefore: .init(clamping: 6), trigger: "общение"),
        Entry(createdAt: now, levelBefore: .init(clamping: 3), trigger: "работа"),
        Entry(createdAt: now, levelBefore: .init(clamping: 3)),
    ]
    let t = Stats.triggers(es, period: .all, now: now)
    #expect(t.map(\.trigger) == ["общение", "работа"])
    #expect(t[0].count == 2)
    #expect(t[0].averageBefore == 7)
}

@Test func periodStartsAndTitles() {
    let now = Date(timeIntervalSince1970: 100 * 86400)
    #expect(Period.days7.start(from: now) == now.addingTimeInterval(-7 * 86400))
    #expect(Period.all.start(from: now) == nil)
    #expect(Period.allCases.map(\.title) == ["7 дней", "30 дней", "90 дней", "всё"])
}
