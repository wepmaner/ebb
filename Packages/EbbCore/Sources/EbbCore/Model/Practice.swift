import Foundation

/// Паттерн дыхания в секундах: вдох / задержка / выдох.
public struct BreathingPattern: Codable, Hashable, Sendable {
    public var inhale: Int
    public var hold: Int
    public var exhale: Int

    public init(inhale: Int, hold: Int, exhale: Int) {
        self.inhale = inhale
        self.hold = hold
        self.exhale = exhale
    }

    public static let calm46 = BreathingPattern(inhale: 4, hold: 0, exhale: 6)
    public static let calm48 = BreathingPattern(inhale: 4, hold: 0, exhale: 8)
    public static let relax478 = BreathingPattern(inhale: 4, hold: 7, exhale: 8)
    public static let presets: [BreathingPattern] = [.calm46, .calm48, .relax478]

    public var cycleSeconds: Int { inhale + hold + exhale }

    public var title: String {
        hold == 0 ? "\(inhale) вдох · \(exhale) выдох" : "\(inhale)-\(hold)-\(exhale)"
    }
}

/// Содержимое сессии практики, зависит от вида практики.
public enum PracticeDetails: Codable, Hashable, Sendable {
    case breathing(pattern: BreathingPattern, plannedSeconds: Int, actualSeconds: Int)
    case grounding(see: [String], touch: [String], hear: [String], smell: [String], taste: [String])
    case thoughtCheck(thought: String, beliefBefore: Int, evidenceFor: String, evidenceAgainst: String, toFriend: String, beliefAfter: Int)
    case deferred(thoughtID: UUID)
    case muscleRelaxation(groupsCompleted: Int, actualSeconds: Int)
}

/// Одна выполненная практика, привязанная к записи или сама по себе.
public struct PracticeSession: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var entryID: UUID?
    public var kind: PracticeKind
    public var startedAt: Date
    public var endedAt: Date
    public var details: PracticeDetails

    public init(id: UUID = UUID(), entryID: UUID? = nil, kind: PracticeKind, startedAt: Date, endedAt: Date, details: PracticeDetails) {
        self.id = id
        self.entryID = entryID
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.details = details
    }

    public var durationSeconds: Int { Int(endedAt.timeIntervalSince(startedAt).rounded()) }
}
