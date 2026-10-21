import EbbCore
import Foundation
import Testing
@testable import Ebb

@Test @MainActor func storeUpsertReloadSnapshotReplace() throws {
    let s = Store.inMemory()
    let e = Entry(levelBefore: .init(clamping: 7), coping: .practice(.breathing), levelAfter: .init(clamping: 3))
    s.upsert(e)
    #expect(s.entries == [e])

    var updated = e
    updated.thought = "после правки"
    s.upsert(updated)
    #expect(s.entries == [updated])

    var snap = s.snapshot(at: Date())
    snap.entries.append(Entry(levelBefore: .init(clamping: 2)))
    try s.replaceAll(with: snap)
    #expect(s.entries.count == 2)

    s.delete(entryID: e.id)
    #expect(s.entries.count == 1)
}

@Test @MainActor func storeKeepsRelatedCollectionsAndSettings() {
    let s = Store.inMemory()
    let e = Entry(levelBefore: .init(clamping: 6), fear: "x", coping: .ownAction("гулял"))
    s.upsert(e)
    s.replaceFearChecks(forEntry: e.id, with: FearCheckScheduler.checks(for: e))
    #expect(s.fearChecks.count == 2)
    s.touchOwnAction("гулял", at: Date())
    s.touchOwnAction("гулял", at: Date())
    #expect(s.ownActions.first?.useCount == 2)
    s.add(PracticeSession(entryID: e.id, kind: .breathing, startedAt: Date(), endedAt: Date(), details: .breathing(pattern: .calm46, plannedSeconds: 120, actualSeconds: 120)))
    #expect(s.sessions.count == 1)
    s.upsert(DailyHabits(day: DayKey(Date()), sleepHours: 6))
    s.upsert(DailyHabits(day: DayKey(Date()), sleepHours: 8))
    #expect(s.habits.count == 1)
    #expect(s.habits.first?.sleepHours == 8)
    var settings = s.settings
    settings.worryTimeHour = 20
    s.save(settings: settings)
    #expect(s.settings.worryTimeHour == 20)
    s.delete(entryID: e.id)
    #expect(s.fearChecks.isEmpty)
    #expect(s.sessions.isEmpty)
}

@Test @MainActor func storeOnChangeFiresOnWrites() {
    let s = Store.inMemory()
    var count = 0
    s.onChange = { count += 1 }
    s.upsert(Entry(levelBefore: .init(clamping: 1)))
    s.save(settings: .defaults)
    #expect(count == 2)
}

@Test @MainActor func demoDataSeedsThirtyDays() {
    let s = Store.inMemory()
    DemoData.seed(into: s, now: Date())
    #expect(s.entries.count >= 30)
    #expect(!s.fearChecks.isEmpty)
    #expect(s.habits.count >= 20)
    #expect(s.entries.contains { $0.isOpen })
    #expect(s.fearChecks.contains { $0.outcome == nil })
}
