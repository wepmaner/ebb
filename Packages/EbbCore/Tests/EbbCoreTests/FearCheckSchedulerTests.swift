import Foundation
import Testing
@testable import EbbCore

private func fearEntry() -> Entry {
    Entry(createdAt: Date(timeIntervalSince1970: 0), levelBefore: .init(clamping: 5), fear: "x")
}

@Test func noFearNoChecks() {
    #expect(FearCheckScheduler.checks(for: Entry(levelBefore: .init(clamping: 5))).isEmpty)
    #expect(FearCheckScheduler.checks(for: Entry(levelBefore: .init(clamping: 5), fear: "   ")).isEmpty)
}

@Test func fearSchedulesThreeAndFourteenDaysAbsolute() {
    let c = FearCheckScheduler.checks(for: fearEntry())
    #expect(c.map(\.stage) == [.day3, .day14])
    #expect(c[0].dueAt.timeIntervalSince1970 == 3 * 86400)
    #expect(c[1].dueAt.timeIntervalSince1970 == 14 * 86400)
}

@Test func dueReturnsOnlyUnansweredPast() {
    let c = FearCheckScheduler.checks(for: fearEntry())
    #expect(FearCheckScheduler.due(c, now: Date(timeIntervalSince1970: 4 * 86400)).map(\.stage) == [.day3])
    #expect(FearCheckScheduler.due(c, now: Date(timeIntervalSince1970: 1 * 86400)).isEmpty)
}

@Test func happenedOnDay3CancelsDay14() {
    let c = FearCheckScheduler.checks(for: fearEntry())
    let out = FearCheckScheduler.answer(c[0], outcome: .happenedBad, in: c, at: Date(timeIntervalSince1970: 4 * 86400))
    #expect(out.count == 1)
    #expect(out[0].outcome == .happenedBad)
    #expect(out[0].answeredAt == Date(timeIntervalSince1970: 4 * 86400))
    let kept = FearCheckScheduler.answer(c[0], outcome: .didNotHappen, in: c, at: Date())
    #expect(kept.count == 2)
    let skipped = FearCheckScheduler.answer(c[0], outcome: .skipped, in: c, at: Date())
    #expect(skipped.count == 2)
    #expect(FearCheckScheduler.due(skipped, now: Date(timeIntervalSince1970: 4 * 86400)).isEmpty)
}
