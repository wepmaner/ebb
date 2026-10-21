import Testing
@testable import EbbCore

@Test func timelinePhases46() {
    let s0 = BreathingTimeline.state(pattern: .calm46, elapsed: 1)
    #expect(s0.phase == .inhale)
    #expect(s0.remaining == 3)
    let s1 = BreathingTimeline.state(pattern: .calm46, elapsed: 4.5)
    #expect(s1.phase == .exhale)
    #expect(s1.remaining == 6)
    let s2 = BreathingTimeline.state(pattern: .calm46, elapsed: 10.0)
    #expect(s2.phase == .inhale)
    #expect(s2.remaining == 4)
}

@Test func timelineProgressWithinPhase() {
    let s = BreathingTimeline.state(pattern: .calm46, elapsed: 2)
    #expect(abs(s.progress - 0.5) < 0.0001)
    let e = BreathingTimeline.state(pattern: .calm46, elapsed: 7)
    #expect(abs(e.progress - 0.5) < 0.0001)
}

@Test func timeline478HasHold() {
    #expect(BreathingTimeline.state(pattern: .relax478, elapsed: 5).phase == .hold)
    #expect(BreathingTimeline.state(pattern: .relax478, elapsed: 12).phase == .exhale)
}
