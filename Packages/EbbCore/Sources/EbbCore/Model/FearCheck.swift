import Foundation

/// Вопрос оглядки: «ты боялся X — это случилось?», через 3 и 14 дней.
public struct FearCheck: Codable, Hashable, Identifiable, Sendable {
    public enum Stage: String, Codable, Sendable { case day3, day14 }
    public enum Outcome: String, Codable, Sendable { case didNotHappen, happenedTolerable, happenedBad, skipped }

    public var id: UUID
    public var entryID: UUID
    public var stage: Stage
    public var dueAt: Date
    public var answeredAt: Date?
    public var outcome: Outcome?

    public init(id: UUID = UUID(), entryID: UUID, stage: Stage, dueAt: Date, answeredAt: Date? = nil, outcome: Outcome? = nil) {
        self.id = id
        self.entryID = entryID
        self.stage = stage
        self.dueAt = dueAt
        self.answeredAt = answeredAt
        self.outcome = outcome
    }

    public var isAnswered: Bool { outcome != nil }
}
