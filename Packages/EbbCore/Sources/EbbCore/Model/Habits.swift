/// Чек-лист привычек за один день.
public struct DailyHabits: Codable, Hashable, Sendable {
    public var day: DayKey
    public var sleepHours: Double?
    public var moved: Bool?
    public var caffeineServings: Int?
    public var alcohol: Bool?
    public var custom: [String: Bool]

    public init(day: DayKey, sleepHours: Double? = nil, moved: Bool? = nil, caffeineServings: Int? = nil, alcohol: Bool? = nil, custom: [String: Bool] = [:]) {
        self.day = day
        self.sleepHours = sleepHours
        self.moved = moved
        self.caffeineServings = caffeineServings
        self.alcohol = alcohol
        self.custom = custom
    }
}
