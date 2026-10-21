import EbbCore
import Foundation
import Testing
@testable import Ebb

@Test @MainActor func sessionFinishesAndReportsActualSeconds() {
    var t = Date(timeIntervalSince1970: 0)
    let s = BreathingSession(pattern: .calm46, plannedSeconds: 20, clock: { t })
    s.start()
    #expect(s.phase == .inhale)
    t = t.addingTimeInterval(4.2)
    s.tick(now: t)
    #expect(s.phase == .exhale)
    #expect(!s.isFinished)
    t = t.addingTimeInterval(16)
    s.tick(now: t)
    #expect(s.isFinished)
    let p = s.stop(entryID: nil)
    if case .breathing(let pattern, let planned, let actual) = p.details {
        #expect(pattern == .calm46)
        #expect(planned == 20)
        #expect(actual == 20)
    } else {
        Issue.record("wrong details")
    }
    #expect(p.kind == .breathing)
}

@Test @MainActor func stoppingEarlyKeepsActualSeconds() {
    var t = Date(timeIntervalSince1970: 100)
    let s = BreathingSession(pattern: .calm48, plannedSeconds: 180, clock: { t })
    s.start()
    t = t.addingTimeInterval(37)
    s.tick(now: t)
    let p = s.stop(entryID: UUID())
    if case .breathing(_, let planned, let actual) = p.details {
        #expect(planned == 180)
        #expect(actual == 37)
    } else {
        Issue.record("wrong details")
    }
    #expect(p.entryID != nil)
}
