import EbbCore
import Foundation

/// Состояние цикла записи: уровень → что сделаешь → практика → уровень после.
@Observable
@MainActor
final class RecordFlowModel: Identifiable {
    enum Step: Hashable {
        case level, suggest, practice(PracticeKind), after
    }

    /// Практики, у которых в этой версии есть экран или действие.
    static let available: Set<PracticeKind> = [.breathing, .deferThought]

    let id = UUID()
    let isResuming: Bool
    private let store: Store
    private let now: () -> Date

    var step: Step
    var draft: Entry
    var recommendation: Recommendation?
    private(set) var session: PracticeSession?
    private(set) var isFinished = false

    init(store: Store, resuming: Entry? = nil, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        if let entry = resuming {
            draft = entry
            step = .after
            isResuming = true
        } else {
            draft = Entry(createdAt: now(), levelBefore: .init(clamping: 5))
            step = .level
            isResuming = false
        }
    }

    // MARK: - Шаг 1 → 2

    func goToSuggest() {
        draft.thought = trimmed(draft.thought)
        draft.fear = trimmed(draft.fear)
        recommendation = Recommender.recommend(level: draft.levelBefore, hasThought: draft.hasThought, hasFear: draft.hasFear, at: now())
        step = .suggest
    }

    /// Рекомендация с учётом того, какие практики уже реализованы.
    var displayedPrimary: Suggestion {
        guard let r = recommendation else { return .practice(.breathing) }
        for candidate in [r.primary, r.fallback, .practice(.breathing)] where isAvailable(candidate) {
            return candidate
        }
        return .practice(.breathing)
    }

    func isAvailable(_ s: Suggestion) -> Bool {
        switch s {
        case .justRecord: true
        case .practice(let kind): Self.available.contains(kind)
        }
    }

    // MARK: - Шаг 2

    func choose(_ s: Suggestion) {
        switch s {
        case .justRecord:
            justRecord()
        case .practice(.deferThought):
            deferThought()
        case .practice(let kind):
            draft.coping = .practice(kind)
            step = .practice(kind)
        }
    }

    func chooseOwnAction(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        draft.coping = .ownAction(clean)
        persistDraft()
        store.touchOwnAction(clean, at: now())
        isFinished = true
    }

    func justRecord() {
        draft.coping = .justRecord
        draft.closedAt = now()
        persistDraft()
        isFinished = true
    }

    func deferThought() {
        draft.coping = .practice(.deferThought)
        draft.closedAt = now()
        persistDraft()
        let text = draft.thought ?? draft.fear ?? ""
        store.add(DeferredThought(entryID: draft.id, text: text, deferredAt: now()))
        isFinished = true
    }

    // MARK: - Шаг 3 → 4

    func finishPractice(session: PracticeSession) {
        self.session = session
        store.add(session)
        step = .after
    }

    func setAfter(_ level: AnxietyLevel) {
        draft.levelAfter = level
        draft.afterAt = now()
    }

    func finish() {
        if draft.levelAfter == nil { draft.closedAt = now() }
        persistDraft()
        isFinished = true
    }

    /// Закрыть поток без сохранения (шаг 1) или с сохранением того, что есть.
    func cancel() {
        isFinished = true
    }

    // MARK: - Внутреннее

    private func persistDraft() {
        store.upsert(draft)
        let hasChecks = store.fearChecks.contains { $0.entryID == draft.id }
        if draft.hasFear, !hasChecks {
            store.replaceFearChecks(forEntry: draft.id, with: FearCheckScheduler.checks(for: draft))
        }
    }

    private func trimmed(_ s: String?) -> String? {
        guard let s else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
