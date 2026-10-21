import Foundation
import Testing
@testable import EbbCore

private let noon = ISO8601DateFormatter().date(from: "2026-10-21T12:00:00Z")!
private let night = ISO8601DateFormatter().date(from: "2026-10-21T23:30:00Z")!
private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}
private func rec(_ level: Int, thought: Bool, fear: Bool = false, at: Date = noon) -> Recommendation {
    Recommender.recommend(level: .init(clamping: level), hasThought: thought, hasFear: fear, at: at, calendar: utc)
}

@Test func highLevelBreathing() {
    let r = rec(8, thought: true)
    #expect(r.primary == .practice(.breathing))
    #expect(r.fallback == .practice(.grounding))
    #expect(!r.offerDefer)
}
@Test func highLevelWithoutThoughtStillBreathing() { #expect(rec(10, thought: false).primary == .practice(.breathing)) }
@Test func midWithThoughtIsThoughtCheck() {
    let r = rec(5, thought: true)
    #expect(r.primary == .practice(.thoughtCheck))
    #expect(r.fallback == .practice(.breathing))
}
@Test func midWithoutThoughtIsBreathing() {
    let r = rec(5, thought: false)
    #expect(r.primary == .practice(.breathing))
    #expect(r.fallback == .practice(.grounding))
}
@Test func lowWithThoughtDefers() {
    let r = rec(2, thought: true)
    #expect(r.primary == .practice(.deferThought))
    #expect(r.fallback == .practice(.thoughtCheck))
}
@Test func lowWithoutThoughtJustRecord() {
    let r = rec(1, thought: false)
    #expect(r.primary == .justRecord)
    #expect(r.fallback == .practice(.breathing))
}
@Test func fearOffersDefer() { #expect(rec(8, thought: true, fear: true).offerDefer) }
@Test func nightFallbackIsRelaxation() {
    #expect(rec(8, thought: true, at: night).fallback == .practice(.muscleRelaxation))
    #expect(rec(8, thought: true, at: night).primary == .practice(.breathing))
    let fiveAM = ISO8601DateFormatter().date(from: "2026-10-21T05:00:00Z")!
    #expect(rec(2, thought: false, at: fiveAM).fallback == .practice(.muscleRelaxation))
}
