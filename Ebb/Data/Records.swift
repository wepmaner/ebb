import Foundation
import SwiftData

// Хранимые записи SwiftData. Логика работает со структурами EbbCore, сюда они маппятся в Mapping.swift.

@Model
final class EntryRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var levelBefore: Int
    var thought: String?
    var trigger: String?
    var fear: String?
    var copingKind: String?
    var copingValue: String?
    var levelAfter: Int?
    var afterAt: Date?
    var closedAt: Date?

    init(id: UUID, createdAt: Date, levelBefore: Int, thought: String?, trigger: String?, fear: String?, copingKind: String?, copingValue: String?, levelAfter: Int?, afterAt: Date?, closedAt: Date?) {
        self.id = id
        self.createdAt = createdAt
        self.levelBefore = levelBefore
        self.thought = thought
        self.trigger = trigger
        self.fear = fear
        self.copingKind = copingKind
        self.copingValue = copingValue
        self.levelAfter = levelAfter
        self.afterAt = afterAt
        self.closedAt = closedAt
    }
}

@Model
final class PracticeSessionRecord {
    @Attribute(.unique) var id: UUID
    var entryID: UUID?
    var kind: String
    var startedAt: Date
    var endedAt: Date
    var detailsJSON: Data

    init(id: UUID, entryID: UUID?, kind: String, startedAt: Date, endedAt: Date, detailsJSON: Data) {
        self.id = id
        self.entryID = entryID
        self.kind = kind
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.detailsJSON = detailsJSON
    }
}

@Model
final class FearCheckRecord {
    @Attribute(.unique) var id: UUID
    var entryID: UUID
    var stage: String
    var dueAt: Date
    var answeredAt: Date?
    var outcome: String?

    init(id: UUID, entryID: UUID, stage: String, dueAt: Date, answeredAt: Date?, outcome: String?) {
        self.id = id
        self.entryID = entryID
        self.stage = stage
        self.dueAt = dueAt
        self.answeredAt = answeredAt
        self.outcome = outcome
    }
}

@Model
final class DailyHabitsRecord {
    @Attribute(.unique) var day: String
    var sleepHours: Double?
    var moved: Bool?
    var caffeineServings: Int?
    var alcohol: Bool?
    var customJSON: Data

    init(day: String, sleepHours: Double?, moved: Bool?, caffeineServings: Int?, alcohol: Bool?, customJSON: Data) {
        self.day = day
        self.sleepHours = sleepHours
        self.moved = moved
        self.caffeineServings = caffeineServings
        self.alcohol = alcohol
        self.customJSON = customJSON
    }
}

@Model
final class OwnActionRecord {
    @Attribute(.unique) var name: String
    var useCount: Int
    var lastUsedAt: Date

    init(name: String, useCount: Int, lastUsedAt: Date) {
        self.name = name
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }
}

@Model
final class LadderStepRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var order: Int
    var completionsJSON: Data

    init(id: UUID, title: String, note: String, order: Int, completionsJSON: Data) {
        self.id = id
        self.title = title
        self.note = note
        self.order = order
        self.completionsJSON = completionsJSON
    }
}

@Model
final class DeferredThoughtRecord {
    @Attribute(.unique) var id: UUID
    var entryID: UUID?
    var text: String
    var deferredAt: Date
    var resolvedAt: Date?
    var resolution: String?

    init(id: UUID, entryID: UUID?, text: String, deferredAt: Date, resolvedAt: Date?, resolution: String?) {
        self.id = id
        self.entryID = entryID
        self.text = text
        self.deferredAt = deferredAt
        self.resolvedAt = resolvedAt
        self.resolution = resolution
    }
}

/// Единственная строка настроек, хранится как JSON структуры UserSettings.
@Model
final class SettingsRecord {
    @Attribute(.unique) var key: String
    var json: Data

    init(key: String = SettingsRecord.singletonKey, json: Data) {
        self.key = key
        self.json = json
    }

    static let singletonKey = "settings"
}
