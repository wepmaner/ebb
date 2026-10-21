import EbbCore
import Foundation
import Testing
@testable import Ebb

@Test @MainActor func entryRoundTripThroughRecord() {
    let e = Entry(levelBefore: .init(clamping: 7), thought: "t", trigger: "работа", fear: "f", coping: .ownAction("гулял"))
    #expect(EntryRecord(e).value == e)
    let closed = Entry(levelBefore: .init(clamping: 7), coping: .practice(.breathing), levelAfter: .init(clamping: 3), afterAt: Date(timeIntervalSince1970: 10), closedAt: nil)
    #expect(EntryRecord(closed).value == closed)
    let plain = Entry(levelBefore: .init(clamping: 2), coping: .justRecord)
    #expect(EntryRecord(plain).value == plain)
}

@Test @MainActor func sessionRoundTripThroughRecord() throws {
    let s = PracticeSession(entryID: UUID(), kind: .thoughtCheck, startedAt: Date(timeIntervalSince1970: 1), endedAt: Date(timeIntervalSince1970: 100), details: .thoughtCheck(thought: "м", beliefBefore: 80, evidenceFor: "за", evidenceAgainst: "против", toFriend: "другу", beliefAfter: 30))
    #expect(try PracticeSessionRecord(s).value() == s)
}

@Test @MainActor func fearCheckHabitsSettingsRoundTrip() throws {
    let c = FearCheck(entryID: UUID(), stage: .day14, dueAt: Date(timeIntervalSince1970: 5), answeredAt: Date(timeIntervalSince1970: 6), outcome: .didNotHappen)
    #expect(FearCheckRecord(c).value == c)
    let h = DailyHabits(day: DayKey(raw: "2026-10-21"), sleepHours: 7.5, moved: false, caffeineServings: 1, alcohol: nil, custom: ["прогулка": true])
    #expect(try DailyHabitsRecord(h).value() == h)
    var settings = UserSettings.defaults
    settings.worryTimeHour = 21
    #expect(try SettingsRecord(settings).value() == settings)
}
