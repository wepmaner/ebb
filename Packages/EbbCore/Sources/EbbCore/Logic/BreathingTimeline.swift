import Foundation

public enum BreathPhase: String, Sendable {
    case inhale, hold, exhale

    public var title: String {
        switch self {
        case .inhale: "Вдох"
        case .hold: "Задержка"
        case .exhale: "Выдох"
        }
    }
}

/// Где мы внутри дыхательного цикла в момент `elapsed`.
public enum BreathingTimeline {
    public struct State: Sendable {
        public var phase: BreathPhase
        /// Целых секунд до конца фазы (с округлением вверх).
        public var remaining: Int
        /// Доля фазы 0…1.
        public var progress: Double
    }

    public static func state(pattern: BreathingPattern, elapsed: TimeInterval) -> State {
        let cycle = Double(max(1, pattern.cycleSeconds))
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        let inhaleEnd = Double(pattern.inhale)
        let holdEnd = inhaleEnd + Double(pattern.hold)
        if t < inhaleEnd {
            return make(.inhale, start: 0, length: Double(pattern.inhale), t: t)
        }
        if t < holdEnd {
            return make(.hold, start: inhaleEnd, length: Double(pattern.hold), t: t)
        }
        return make(.exhale, start: holdEnd, length: Double(pattern.exhale), t: t)
    }

    private static func make(_ phase: BreathPhase, start: Double, length: Double, t: Double) -> State {
        let into = t - start
        let left = length - into
        return State(phase: phase, remaining: Int(left.rounded(.up)), progress: length > 0 ? into / length : 1)
    }
}
