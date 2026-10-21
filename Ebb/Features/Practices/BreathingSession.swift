import EbbCore
import Foundation

/// Таймер одной дыхательной сессии. Тикает извне, чтобы быть тестируемым.
@Observable
@MainActor
final class BreathingSession {
    let pattern: BreathingPattern
    let plannedSeconds: Int
    private let clock: () -> Date
    private var startedAt: Date?
    private var lastPhase: BreathPhase?

    private(set) var elapsed: TimeInterval = 0
    private(set) var phase: BreathPhase = .inhale
    private(set) var remaining: Int
    private(set) var progress: Double = 0
    private(set) var isFinished = false

    init(pattern: BreathingPattern, plannedSeconds: Int, clock: @escaping () -> Date = Date.init) {
        self.pattern = pattern
        self.plannedSeconds = plannedSeconds
        self.clock = clock
        self.remaining = pattern.inhale
    }

    var isRunning: Bool { startedAt != nil && !isFinished }
    var secondsLeft: Int { max(0, plannedSeconds - Int(elapsed.rounded(.down))) }

    func start() {
        let now = clock()
        startedAt = now
        tick(now: now)
    }

    func tick(now: Date) {
        guard let startedAt, !isFinished else { return }
        elapsed = min(now.timeIntervalSince(startedAt), Double(plannedSeconds))
        let state = BreathingTimeline.state(pattern: pattern, elapsed: elapsed)
        phase = state.phase
        remaining = state.remaining
        progress = state.progress
        if let last = lastPhase, last != phase { Haptics.phase() }
        lastPhase = phase
        if elapsed >= Double(plannedSeconds) { isFinished = true }
    }

    func stop(entryID: UUID? = nil) -> PracticeSession {
        let end = clock()
        isFinished = true
        return PracticeSession(
            entryID: entryID,
            kind: .breathing,
            startedAt: startedAt ?? end,
            endedAt: end,
            details: .breathing(pattern: pattern, plannedSeconds: plannedSeconds, actualSeconds: Int(elapsed.rounded()))
        )
    }
}
