import Foundation

/// Триггер тревоги (чип на шаге 1).
public struct Trigger: Codable, Hashable, Sendable {
    public var name: String
    public var isBuiltIn: Bool

    public init(name: String, isBuiltIn: Bool = false) {
        self.name = name
        self.isBuiltIn = isBuiltIn
    }

    public static let defaults: [Trigger] = ["общение", "работа", "здоровье", "деньги", "отношения", "не знаю"]
        .map { Trigger(name: $0, isBuiltIn: true) }
}

/// Практики, встроенные в приложение.
public enum PracticeKind: String, Codable, CaseIterable, Sendable {
    case breathing, grounding, thoughtCheck, deferThought, muscleRelaxation

    public var title: String {
        switch self {
        case .breathing: "Дыхание"
        case .grounding: "Заземление 5-4-3-2-1"
        case .thoughtCheck: "Проверка мысли"
        case .deferThought: "Отложить мысль"
        case .muscleRelaxation: "Мышечная релаксация"
        }
    }
}

/// Своё действие пользователя («гулял», «работал»), запоминается для чипов.
public struct OwnAction: Codable, Hashable, Sendable {
    public var name: String
    public var useCount: Int
    public var lastUsedAt: Date

    public init(name: String, useCount: Int = 1, lastUsedAt: Date = Date()) {
        self.name = name
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }
}

/// Шаг лестницы навстречу страху.
public struct LadderStep: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var note: String
    public var order: Int
    public var completions: [Date]

    public init(id: UUID = UUID(), title: String, note: String = "", order: Int, completions: [Date] = []) {
        self.id = id
        self.title = title
        self.note = note
        self.order = order
        self.completions = completions
    }
}

/// Мысль, отложенная до «времени для тревоги».
public struct DeferredThought: Codable, Hashable, Identifiable, Sendable {
    public enum Resolution: String, Codable, Sendable {
        case noLongerWorries, checked, kept
    }

    public var id: UUID
    public var entryID: UUID?
    public var text: String
    public var deferredAt: Date
    public var resolvedAt: Date?
    public var resolution: Resolution?

    public init(id: UUID = UUID(), entryID: UUID? = nil, text: String, deferredAt: Date = Date(), resolvedAt: Date? = nil, resolution: Resolution? = nil) {
        self.id = id
        self.entryID = entryID
        self.text = text
        self.deferredAt = deferredAt
        self.resolvedAt = resolvedAt
        self.resolution = resolution
    }
}
