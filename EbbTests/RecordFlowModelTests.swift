import EbbCore
import Foundation
import Testing
@testable import Ebb

@Test @MainActor func ownActionLeavesEntryOpenAndSaves() {
    let s = Store.inMemory()
    let m = RecordFlowModel(store: s)
    m.draft.levelBefore = .init(clamping: 7)
    m.goToSuggest()
    m.chooseOwnAction("гулял")
    #expect(s.entries.count == 1)
    #expect(s.entries[0].isOpen)
    #expect(s.ownActions.map(\.name) == ["гулял"])
    #expect(m.isFinished)
}

@Test @MainActor func fearCreatesChecksOnFinish() {
    let s = Store.inMemory()
    let m = RecordFlowModel(store: s)
    m.draft.levelBefore = .init(clamping: 8)
    m.draft.fear = "x"
    m.goToSuggest()
    #expect(m.recommendation?.primary == .practice(.breathing))
    #expect(m.recommendation?.offerDefer == true)
    m.choose(.practice(.breathing))
    #expect(m.step == .practice(.breathing))
    m.finishPractice(session: PracticeSession(entryID: m.draft.id, kind: .breathing, startedAt: Date(), endedAt: Date(), details: .breathing(pattern: .calm46, plannedSeconds: 180, actualSeconds: 170)))
    #expect(m.step == .after)
    m.setAfter(.init(clamping: 3))
    m.finish()
    #expect(s.entries[0].delta == -4)
    #expect(s.fearChecks.count == 2)
    #expect(s.sessions.count == 1)
    #expect(m.isFinished)
}

@Test @MainActor func resumingOpenEntryStartsAtAfterStep() {
    let s = Store.inMemory()
    let e = Entry(levelBefore: .init(clamping: 6), coping: .ownAction("работал"))
    s.upsert(e)
    let m = RecordFlowModel(store: s, resuming: e)
    #expect(m.step == .after)
    m.setAfter(.init(clamping: 6))
    m.finish()
    #expect(s.entries[0].delta == 0)
    #expect(!s.entries[0].isOpen)
}

@Test @MainActor func justRecordAndDeferCloseImmediately() {
    let s = Store.inMemory()
    let m = RecordFlowModel(store: s)
    m.draft.levelBefore = .init(clamping: 2)
    m.goToSuggest()
    #expect(m.recommendation?.primary == .justRecord)
    m.choose(.justRecord)
    #expect(s.entries[0].coping == .justRecord)
    #expect(s.entries[0].closedAt != nil)

    let m2 = RecordFlowModel(store: s)
    m2.draft.levelBefore = .init(clamping: 5)
    m2.draft.thought = "мысль"
    m2.goToSuggest()
    m2.deferThought()
    #expect(s.deferred.first?.text == "мысль")
    #expect(s.entries.count == 2)
}

@Test @MainActor func unavailablePracticeFallsBackToBreathing() {
    let s = Store.inMemory()
    let m = RecordFlowModel(store: s)
    m.draft.levelBefore = .init(clamping: 5)
    m.draft.thought = "мысль"
    m.goToSuggest()
    #expect(m.recommendation?.primary == .practice(.thoughtCheck))
    #expect(m.displayedPrimary == .practice(.breathing))
}
