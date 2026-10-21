import Foundation
import Testing
@testable import EbbCore

@Test func snapshotRoundTripPreservesEverything() throws {
    var s = Snapshot.empty(at: Date(timeIntervalSince1970: 1_800_000_000))
    s.entries = [Entry(levelBefore: .init(clamping: 8), thought: "t", coping: .practice(.breathing), levelAfter: .init(clamping: 4))]
    s.sessions = [PracticeSession(entryID: s.entries[0].id, kind: .breathing, startedAt: .init(timeIntervalSince1970: 1), endedAt: .init(timeIntervalSince1970: 181), details: .breathing(pattern: .calm46, plannedSeconds: 180, actualSeconds: 180))]
    s.fearChecks = [FearCheck(entryID: s.entries[0].id, stage: .day3, dueAt: .init(timeIntervalSince1970: 2))]
    s.habits = [DailyHabits(day: DayKey(Date(timeIntervalSince1970: 0)), sleepHours: 6.5, moved: true, caffeineServings: 2, alcohol: false, custom: ["прогулка": true])]
    s.ownActions = [OwnAction(name: "гулял", useCount: 3, lastUsedAt: .init(timeIntervalSince1970: 5))]
    s.ladder = [LadderStep(title: "позвонить", order: 0)]
    s.deferred = [DeferredThought(text: "мысль", deferredAt: .init(timeIntervalSince1970: 9))]
    let data = try JSONEncoder().encode(s)
    let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
    #expect(decoded == s)
    #expect(s.schemaVersion == EbbCore.schemaVersion)
}

@Test func defaultSettingsMatchSpec() {
    let d = UserSettings.defaults
    #expect(d.worryTimeHour == 19)
    #expect(d.worryTimeReminder == false)
    #expect(d.planReminders == false)
    #expect(d.plan.count == 4)
    #expect(d.plan.map(\.kind) == [.breathing, .breathing, .muscleRelaxation, nil])
    #expect(d.triggers.map(\.name) == ["общение", "работа", "здоровье", "деньги", "отношения", "не знаю"])
}

@Test func breathingPresetsAndCycle() {
    #expect(BreathingPattern.calm46.cycleSeconds == 10)
    #expect(BreathingPattern.calm48.cycleSeconds == 12)
    #expect(BreathingPattern.relax478 == BreathingPattern(inhale: 4, hold: 7, exhale: 8))
}
