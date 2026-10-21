import EbbCore
import Foundation

// Record ↔ структура EbbCore. JSON-поля кодируются одним и тем же кодеком.

/// Кодеки создаются на каждый вызов: методы @Model-классов неизолированные, а
/// JSONEncoder не Sendable, поэтому общий экземпляр под MainActor здесь нельзя.
private enum JSON {
    nonisolated static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    nonisolated static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

// MARK: - Entry

extension EntryRecord {
    convenience init(_ e: Entry) {
        let (kind, value) = EntryRecord.encode(e.coping)
        self.init(id: e.id, createdAt: e.createdAt, levelBefore: e.levelBefore.value, thought: e.thought, trigger: e.trigger, fear: e.fear, copingKind: kind, copingValue: value, levelAfter: e.levelAfter?.value, afterAt: e.afterAt, closedAt: e.closedAt)
    }

    func apply(_ e: Entry) {
        createdAt = e.createdAt
        levelBefore = e.levelBefore.value
        thought = e.thought
        trigger = e.trigger
        fear = e.fear
        (copingKind, copingValue) = EntryRecord.encode(e.coping)
        levelAfter = e.levelAfter?.value
        afterAt = e.afterAt
        closedAt = e.closedAt
    }

    var value: Entry {
        Entry(id: id, createdAt: createdAt, levelBefore: .init(clamping: levelBefore), thought: thought, trigger: trigger, fear: fear, coping: EntryRecord.decode(kind: copingKind, value: copingValue), levelAfter: levelAfter.map { .init(clamping: $0) }, afterAt: afterAt, closedAt: closedAt)
    }

    static func encode(_ coping: CopingMethod?) -> (String?, String?) {
        switch coping {
        case .none: (nil, nil)
        case .practice(let kind): ("practice", kind.rawValue)
        case .ownAction(let name): ("ownAction", name)
        case .justRecord: ("justRecord", nil)
        }
    }

    static func decode(kind: String?, value: String?) -> CopingMethod? {
        switch kind {
        case "practice": value.flatMap(PracticeKind.init(rawValue:)).map(CopingMethod.practice)
        case "ownAction": value.map(CopingMethod.ownAction)
        case "justRecord": .justRecord
        default: nil
        }
    }
}

// MARK: - PracticeSession

extension PracticeSessionRecord {
    convenience init(_ s: PracticeSession) {
        self.init(id: s.id, entryID: s.entryID, kind: s.kind.rawValue, startedAt: s.startedAt, endedAt: s.endedAt, detailsJSON: (try? JSON.encoder.encode(s.details)) ?? Data())
    }

    func value() throws -> PracticeSession {
        PracticeSession(id: id, entryID: entryID, kind: PracticeKind(rawValue: kind) ?? .breathing, startedAt: startedAt, endedAt: endedAt, details: try JSON.decoder.decode(PracticeDetails.self, from: detailsJSON))
    }
}

// MARK: - FearCheck

extension FearCheckRecord {
    convenience init(_ c: FearCheck) {
        self.init(id: c.id, entryID: c.entryID, stage: c.stage.rawValue, dueAt: c.dueAt, answeredAt: c.answeredAt, outcome: c.outcome?.rawValue)
    }

    func apply(_ c: FearCheck) {
        entryID = c.entryID
        stage = c.stage.rawValue
        dueAt = c.dueAt
        answeredAt = c.answeredAt
        outcome = c.outcome?.rawValue
    }

    var value: FearCheck {
        FearCheck(id: id, entryID: entryID, stage: FearCheck.Stage(rawValue: stage) ?? .day3, dueAt: dueAt, answeredAt: answeredAt, outcome: outcome.flatMap(FearCheck.Outcome.init(rawValue:)))
    }
}

// MARK: - DailyHabits

extension DailyHabitsRecord {
    convenience init(_ h: DailyHabits) {
        self.init(day: h.day.raw, sleepHours: h.sleepHours, moved: h.moved, caffeineServings: h.caffeineServings, alcohol: h.alcohol, customJSON: (try? JSON.encoder.encode(h.custom)) ?? Data())
    }

    func apply(_ h: DailyHabits) {
        sleepHours = h.sleepHours
        moved = h.moved
        caffeineServings = h.caffeineServings
        alcohol = h.alcohol
        customJSON = (try? JSON.encoder.encode(h.custom)) ?? Data()
    }

    func value() throws -> DailyHabits {
        DailyHabits(day: DayKey(raw: day), sleepHours: sleepHours, moved: moved, caffeineServings: caffeineServings, alcohol: alcohol, custom: customJSON.isEmpty ? [:] : try JSON.decoder.decode([String: Bool].self, from: customJSON))
    }
}

// MARK: - OwnAction

extension OwnActionRecord {
    convenience init(_ a: OwnAction) {
        self.init(name: a.name, useCount: a.useCount, lastUsedAt: a.lastUsedAt)
    }

    var value: OwnAction { OwnAction(name: name, useCount: useCount, lastUsedAt: lastUsedAt) }
}

// MARK: - LadderStep

extension LadderStepRecord {
    convenience init(_ s: LadderStep) {
        self.init(id: s.id, title: s.title, note: s.note, order: s.order, completionsJSON: (try? JSON.encoder.encode(s.completions)) ?? Data())
    }

    func apply(_ s: LadderStep) {
        title = s.title
        note = s.note
        order = s.order
        completionsJSON = (try? JSON.encoder.encode(s.completions)) ?? Data()
    }

    func value() throws -> LadderStep {
        LadderStep(id: id, title: title, note: note, order: order, completions: completionsJSON.isEmpty ? [] : try JSON.decoder.decode([Date].self, from: completionsJSON))
    }
}

// MARK: - DeferredThought

extension DeferredThoughtRecord {
    convenience init(_ d: DeferredThought) {
        self.init(id: d.id, entryID: d.entryID, text: d.text, deferredAt: d.deferredAt, resolvedAt: d.resolvedAt, resolution: d.resolution?.rawValue)
    }

    func apply(_ d: DeferredThought) {
        entryID = d.entryID
        text = d.text
        deferredAt = d.deferredAt
        resolvedAt = d.resolvedAt
        resolution = d.resolution?.rawValue
    }

    var value: DeferredThought {
        DeferredThought(id: id, entryID: entryID, text: text, deferredAt: deferredAt, resolvedAt: resolvedAt, resolution: resolution.flatMap(DeferredThought.Resolution.init(rawValue:)))
    }
}

// MARK: - Settings

extension SettingsRecord {
    convenience init(_ s: UserSettings) {
        self.init(json: (try? JSON.encoder.encode(s)) ?? Data())
    }

    func apply(_ s: UserSettings) {
        json = (try? JSON.encoder.encode(s)) ?? Data()
    }

    func value() throws -> UserSettings {
        try JSON.decoder.decode(UserSettings.self, from: json)
    }
}
