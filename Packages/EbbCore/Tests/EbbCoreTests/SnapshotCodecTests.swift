import Foundation
import Testing
@testable import EbbCore

@Test func codecRoundTrip() throws {
    var s = Snapshot.empty(at: Date(timeIntervalSince1970: 1_800_000_000))
    s.entries = [Entry(createdAt: Date(timeIntervalSince1970: 1_799_999_000), levelBefore: .init(clamping: 7), thought: "т", coping: .ownAction("гулял"))]
    let data = try SnapshotCodec.encode(s)
    let decoded = try SnapshotCodec.decode(data)
    #expect(decoded == s)
    #expect(String(decoding: data, as: UTF8.self).contains("\"schemaVersion\" : 1"))
}

@Test func codecKeepsMillisecondsAndReadsWholeSeconds() throws {
    let d = EbbDates.rounded(Date(timeIntervalSince1970: 1_800_000_000.123))
    var s = Snapshot.empty(at: d)
    s.entries = [Entry(createdAt: d, levelBefore: .init(clamping: 1))]
    let back = try SnapshotCodec.decode(SnapshotCodec.encode(s))
    #expect(back.entries[0].createdAt == d)
    #expect(back == s)
    let legacy = Data("{\"schemaVersion\":1,\"exportedAt\":\"2026-10-21T10:00:00Z\",\"entries\":[],\"sessions\":[],\"fearChecks\":[],\"habits\":[],\"ownActions\":[],\"ladder\":[],\"deferred\":[],\"settings\":{\"worryTimeHour\":19,\"worryTimeReminder\":false,\"planReminders\":false,\"plan\":[],\"triggers\":[],\"customHabits\":[]}}".utf8)
    let old = try SnapshotCodec.decode(legacy)
    #expect(old.exportedAt == Date(timeIntervalSince1970: 1_792_576_800))
}

@Test func codecRejectsCorruptedData() {
    #expect(throws: SnapshotError.self) { try SnapshotCodec.decode(Data("{\"schemaVersion\":1,\"entries\":[".utf8)) }
    #expect(throws: SnapshotError.self) { try SnapshotCodec.decode(Data()) }
}

@Test func codecRejectsUnsupportedVersion() {
    #expect(throws: SnapshotError.unsupportedVersion(99)) { try SnapshotCodec.decode(Data("{\"schemaVersion\":99}".utf8)) }
}

@Test func modelInitsRoundDatesToMilliseconds() {
    let raw = Date(timeIntervalSince1970: 1_800_000_000.123_456_7)
    let expected = Date(timeIntervalSince1970: 1_800_000_000.123)
    #expect(Entry(createdAt: raw, levelBefore: .init(clamping: 1), afterAt: raw).afterAt == expected)
    #expect(FearCheck(entryID: UUID(), stage: .day3, dueAt: raw).dueAt == expected)
    #expect(PracticeSession(kind: .breathing, startedAt: raw, endedAt: raw, details: .deferred(thoughtID: UUID())).endedAt == expected)
    #expect(OwnAction(name: "x", lastUsedAt: raw).lastUsedAt == expected)
    #expect(DeferredThought(text: "t", deferredAt: raw).deferredAt == expected)
    #expect(LadderStep(title: "s", order: 0, completions: [raw]).completions == [expected])
}
