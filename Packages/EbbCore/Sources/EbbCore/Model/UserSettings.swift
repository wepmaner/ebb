/// Пункт плана дня. `kind == nil` означает чек-лист привычек.
public struct PlanItem: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var kind: PracticeKind?
    public var title: String
    public var hour: Int
    public var enabled: Bool

    public init(id: String, kind: PracticeKind?, title: String, hour: Int, enabled: Bool = true) {
        self.id = id
        self.kind = kind
        self.title = title
        self.hour = hour
        self.enabled = enabled
    }
}

/// Настройки пользователя. Входят в резервную копию.
public struct UserSettings: Codable, Hashable, Sendable {
    public var worryTimeHour: Int
    public var worryTimeReminder: Bool
    public var planReminders: Bool
    public var plan: [PlanItem]
    public var triggers: [Trigger]
    public var customHabits: [String]
    public var exportPrompt: String?

    public init(
        worryTimeHour: Int = 19,
        worryTimeReminder: Bool = false,
        planReminders: Bool = false,
        plan: [PlanItem] = UserSettings.defaultPlan,
        triggers: [Trigger] = Trigger.defaults,
        customHabits: [String] = [],
        exportPrompt: String? = nil
    ) {
        self.worryTimeHour = worryTimeHour
        self.worryTimeReminder = worryTimeReminder
        self.planReminders = planReminders
        self.plan = plan
        self.triggers = triggers
        self.customHabits = customHabits
        self.exportPrompt = exportPrompt
    }

    public static let defaults = UserSettings()

    public static let defaultPlan: [PlanItem] = [
        PlanItem(id: "breathing-morning", kind: .breathing, title: "Дыхание утром", hour: 8),
        PlanItem(id: "breathing-evening", kind: .breathing, title: "Дыхание вечером", hour: 20),
        PlanItem(id: "relaxation-night", kind: .muscleRelaxation, title: "Релаксация перед сном", hour: 22),
        PlanItem(id: "habits", kind: nil, title: "Привычки за день", hour: 18),
    ]
}
