import Foundation
import Testing
@testable import EbbCore

@Test func autoCloseClosesOnlyStaleOpenEntries() {
    let now = Date(timeIntervalSince1970: 100_000)
    let stale = Entry(createdAt: now.addingTimeInterval(-13 * 3600), levelBefore: .init(clamping: 6), coping: .ownAction("работал"))
    let fresh = Entry(createdAt: now.addingTimeInterval(-1 * 3600), levelBefore: .init(clamping: 6), coping: .ownAction("гулял"))
    let closed = Entry(createdAt: now.addingTimeInterval(-20 * 3600), levelBefore: .init(clamping: 6), coping: .practice(.breathing), levelAfter: .init(clamping: 2))
    let out = EntryLifecycle.autoClose([stale, fresh, closed], now: now)
    #expect(out[0].closedAt == now)
    #expect(out[0].levelAfter == nil)
    #expect(out[1].isOpen)
    #expect(out[2] == closed)
    #expect(EntryLifecycle.openEntries(out).map(\.id) == [fresh.id])
}

@Test func multipleOpenEntriesAreHandledIndependently() {
    let now = Date(timeIntervalSince1970: 100_000)
    let a = Entry(createdAt: now.addingTimeInterval(-14 * 3600), levelBefore: .init(clamping: 5), coping: .ownAction("играл"))
    let b = Entry(createdAt: now.addingTimeInterval(-2 * 3600), levelBefore: .init(clamping: 7), coping: .ownAction("гулял"))
    let c = Entry(createdAt: now.addingTimeInterval(-30 * 60), levelBefore: .init(clamping: 4), coping: .ownAction("работал"))
    let out = EntryLifecycle.autoClose([a, b, c], now: now)
    #expect(out.map(\.isOpen) == [false, true, true])
    #expect(EntryLifecycle.openEntries(out).map(\.id) == [c.id, b.id])
}
