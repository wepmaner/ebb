import Foundation

/// Чем человек справлялся с тревогой в этой записи.
public enum CopingMethod: Codable, Hashable, Sendable {
    case practice(PracticeKind)
    case ownAction(String)
    case justRecord

    public var displayName: String {
        switch self {
        case .practice(let kind): kind.title
        case .ownAction(let name): name
        case .justRecord: "Просто записал"
        }
    }
}

/// Одна запись дневника: замер до, мысль, триггер, страх, действие, замер после.
public struct Entry: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var levelBefore: AnxietyLevel
    public var thought: String?
    public var trigger: String?
    public var fear: String?
    public var coping: CopingMethod?
    public var levelAfter: AnxietyLevel?
    public var afterAt: Date?
    public var closedAt: Date?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        levelBefore: AnxietyLevel,
        thought: String? = nil,
        trigger: String? = nil,
        fear: String? = nil,
        coping: CopingMethod? = nil,
        levelAfter: AnxietyLevel? = nil,
        afterAt: Date? = nil,
        closedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.levelBefore = levelBefore
        self.thought = thought
        self.trigger = trigger
        self.fear = fear
        self.coping = coping
        self.levelAfter = levelAfter
        self.afterAt = afterAt
        self.closedAt = closedAt
    }

    /// Открыта: своё действие без замера «после» и без автозакрытия.
    public var isOpen: Bool {
        if case .ownAction = coping { return levelAfter == nil && closedAt == nil }
        return false
    }

    /// Изменение уровня (после − до); nil без замера «после».
    public var delta: Int? {
        levelAfter.map { $0.value - levelBefore.value }
    }

    public var hasFear: Bool {
        !(fear ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var hasThought: Bool {
        !(thought ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
