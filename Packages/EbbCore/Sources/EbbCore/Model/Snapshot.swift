import Foundation

/// Всё содержимое приложения одним значением: формат резервной копии и экспорта.
public struct Snapshot: Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var exportedAt: Date
    public var entries: [Entry]
    public var sessions: [PracticeSession]
    public var fearChecks: [FearCheck]
    public var habits: [DailyHabits]
    public var ownActions: [OwnAction]
    public var ladder: [LadderStep]
    public var deferred: [DeferredThought]
    public var settings: UserSettings

    public init(
        schemaVersion: Int = EbbCore.schemaVersion,
        exportedAt: Date,
        entries: [Entry] = [],
        sessions: [PracticeSession] = [],
        fearChecks: [FearCheck] = [],
        habits: [DailyHabits] = [],
        ownActions: [OwnAction] = [],
        ladder: [LadderStep] = [],
        deferred: [DeferredThought] = [],
        settings: UserSettings = .defaults
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.entries = entries
        self.sessions = sessions
        self.fearChecks = fearChecks
        self.habits = habits
        self.ownActions = ownActions
        self.ladder = ladder
        self.deferred = deferred
        self.settings = settings
    }

    public static func empty(at date: Date) -> Snapshot { Snapshot(exportedAt: date) }
}
