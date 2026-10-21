import EbbCore
import Foundation
import SwiftData

/// Фасад над SwiftData. Экраны читают структуры EbbCore и пишут через методы ниже.
@Observable
@MainActor
final class Store {
    static let schema = Schema([
        EntryRecord.self, PracticeSessionRecord.self, FearCheckRecord.self, DailyHabitsRecord.self,
        OwnActionRecord.self, LadderStepRecord.self, DeferredThoughtRecord.self, SettingsRecord.self,
    ])

    let container: ModelContainer
    private let context: ModelContext

    private(set) var entries: [Entry] = []
    private(set) var sessions: [PracticeSession] = []
    private(set) var fearChecks: [FearCheck] = []
    private(set) var habits: [DailyHabits] = []
    private(set) var ownActions: [OwnAction] = []
    private(set) var ladder: [LadderStep] = []
    private(set) var deferred: [DeferredThought] = []
    private(set) var settings: UserSettings = .defaults

    /// Вызывается после каждой записи. Сюда подключается резервная копия.
    var onChange: (() -> Void)?

    init(container: ModelContainer) {
        self.container = container
        self.context = container.mainContext
        context.autosaveEnabled = false
        reload()
    }

    static func inMemory() -> Store {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: config)
        return Store(container: container)
    }

    static func persistent() throws -> Store {
        // SwiftData не создаёт Application Support сама; на свежем контейнере её нет.
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let config = ModelConfiguration("Ebb", schema: schema, url: support.appending(path: "Ebb.store"))
        return Store(container: try ModelContainer(for: schema, configurations: config))
    }

    var isEmpty: Bool { entries.isEmpty && sessions.isEmpty && habits.isEmpty && ladder.isEmpty }

    // MARK: - Чтение

    func reload() {
        entries = fetchAll(EntryRecord.self).map(\.value).sorted { $0.createdAt > $1.createdAt }
        sessions = fetchAll(PracticeSessionRecord.self).compactMap { try? $0.value() }.sorted { $0.startedAt > $1.startedAt }
        fearChecks = fetchAll(FearCheckRecord.self).map(\.value).sorted { $0.dueAt < $1.dueAt }
        habits = fetchAll(DailyHabitsRecord.self).compactMap { try? $0.value() }.sorted { $0.day < $1.day }
        ownActions = fetchAll(OwnActionRecord.self).map(\.value).sorted { $0.useCount != $1.useCount ? $0.useCount > $1.useCount : $0.lastUsedAt > $1.lastUsedAt }
        ladder = fetchAll(LadderStepRecord.self).compactMap { try? $0.value() }.sorted { $0.order < $1.order }
        deferred = fetchAll(DeferredThoughtRecord.self).map(\.value).sorted { $0.deferredAt > $1.deferredAt }
        settings = (try? fetchAll(SettingsRecord.self).first?.value()) ?? .defaults
    }

    // MARK: - Записи

    func upsert(_ e: Entry) {
        let id = e.id
        if let record = fetchOne(EntryRecord.self, #Predicate { $0.id == id }) {
            record.apply(e)
        } else {
            context.insert(EntryRecord(e))
        }
        commit()
    }

    func delete(entryID: UUID) {
        if let record = fetchOne(EntryRecord.self, #Predicate { $0.id == entryID }) { context.delete(record) }
        for c in fetchAll(FearCheckRecord.self, #Predicate { $0.entryID == entryID }) { context.delete(c) }
        for s in fetchAll(PracticeSessionRecord.self, #Predicate { $0.entryID == entryID }) { context.delete(s) }
        commit()
    }

    // MARK: - Практики

    func add(_ s: PracticeSession) {
        context.insert(PracticeSessionRecord(s))
        commit()
    }

    // MARK: - Оглядка

    func upsert(_ c: FearCheck) {
        let id = c.id
        if let record = fetchOne(FearCheckRecord.self, #Predicate { $0.id == id }) {
            record.apply(c)
        } else {
            context.insert(FearCheckRecord(c))
        }
        commit()
    }

    func replaceFearChecks(forEntry entryID: UUID, with checks: [FearCheck]) {
        for old in fetchAll(FearCheckRecord.self, #Predicate { $0.entryID == entryID }) { context.delete(old) }
        for c in checks { context.insert(FearCheckRecord(c)) }
        commit()
    }

    // MARK: - Привычки

    func upsert(_ h: DailyHabits) {
        let day = h.day.raw
        if let record = fetchOne(DailyHabitsRecord.self, #Predicate { $0.day == day }) {
            record.apply(h)
        } else {
            context.insert(DailyHabitsRecord(h))
        }
        commit()
    }

    // MARK: - Свои действия

    func touchOwnAction(_ name: String, at date: Date) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let record = fetchOne(OwnActionRecord.self, #Predicate { $0.name == trimmed }) {
            record.useCount += 1
            record.lastUsedAt = EbbDates.rounded(date)
        } else {
            context.insert(OwnActionRecord(name: trimmed, useCount: 1, lastUsedAt: EbbDates.rounded(date)))
        }
        commit()
    }

    // MARK: - Лестница и отложенные мысли

    func upsert(_ step: LadderStep) {
        let id = step.id
        if let record = fetchOne(LadderStepRecord.self, #Predicate { $0.id == id }) {
            record.apply(step)
        } else {
            context.insert(LadderStepRecord(step))
        }
        commit()
    }

    func add(_ d: DeferredThought) {
        context.insert(DeferredThoughtRecord(d))
        commit()
    }

    func upsert(_ d: DeferredThought) {
        let id = d.id
        if let record = fetchOne(DeferredThoughtRecord.self, #Predicate { $0.id == id }) {
            record.apply(d)
        } else {
            context.insert(DeferredThoughtRecord(d))
        }
        commit()
    }

    // MARK: - Настройки

    func save(settings s: UserSettings) {
        if let record = fetchAll(SettingsRecord.self).first {
            record.apply(s)
        } else {
            context.insert(SettingsRecord(s))
        }
        commit()
    }

    // MARK: - Снимок целиком

    func snapshot(at date: Date) -> Snapshot {
        Snapshot(exportedAt: date, entries: entries, sessions: sessions, fearChecks: fearChecks, habits: habits, ownActions: ownActions, ladder: ladder, deferred: deferred, settings: settings)
    }

    /// Заменяет всё содержимое базы. При ошибке сохранения откатывает контекст.
    func replaceAll(with s: Snapshot) throws {
        deleteAll()
        s.entries.forEach { context.insert(EntryRecord($0)) }
        s.sessions.forEach { context.insert(PracticeSessionRecord($0)) }
        s.fearChecks.forEach { context.insert(FearCheckRecord($0)) }
        s.habits.forEach { context.insert(DailyHabitsRecord($0)) }
        s.ownActions.forEach { context.insert(OwnActionRecord($0)) }
        s.ladder.forEach { context.insert(LadderStepRecord($0)) }
        s.deferred.forEach { context.insert(DeferredThoughtRecord($0)) }
        context.insert(SettingsRecord(s.settings))
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        reload()
        onChange?()
    }

    // MARK: - Внутреннее

    private func deleteAll() {
        fetchAll(EntryRecord.self).forEach(context.delete)
        fetchAll(PracticeSessionRecord.self).forEach(context.delete)
        fetchAll(FearCheckRecord.self).forEach(context.delete)
        fetchAll(DailyHabitsRecord.self).forEach(context.delete)
        fetchAll(OwnActionRecord.self).forEach(context.delete)
        fetchAll(LadderStepRecord.self).forEach(context.delete)
        fetchAll(DeferredThoughtRecord.self).forEach(context.delete)
        fetchAll(SettingsRecord.self).forEach(context.delete)
    }

    private func commit() {
        do {
            try context.save()
        } catch {
            context.rollback()
            assertionFailure("save failed: \(error)")
        }
        reload()
        onChange?()
    }

    private func fetchAll<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>? = nil) -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
}
