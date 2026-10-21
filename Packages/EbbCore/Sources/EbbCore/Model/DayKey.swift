import Foundation

/// Календарный день "YYYY-MM-DD" в локальном календаре пользователя.
public struct DayKey: Codable, Hashable, Sendable, Comparable {
    public let raw: String

    public init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        raw = String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public init(raw: String) { self.raw = raw }

    public init(from decoder: Decoder) throws {
        raw = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(raw)
    }

    /// Полночь этого дня в указанном календаре.
    public func date(calendar: Calendar = .current) -> Date {
        let parts = raw.split(separator: "-").compactMap { Int($0) }
        var c = DateComponents()
        c.year = parts.count > 0 ? parts[0] : nil
        c.month = parts.count > 1 ? parts[1] : nil
        c.day = parts.count > 2 ? parts[2] : nil
        return calendar.date(from: c) ?? .distantPast
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.raw < rhs.raw }
}
