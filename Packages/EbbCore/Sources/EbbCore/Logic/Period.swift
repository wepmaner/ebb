import Foundation

/// Период для статистики и экспорта.
public enum Period: String, CaseIterable, Codable, Sendable {
    case days7, days30, days90, all

    /// Начало периода; nil для «всё».
    public func start(from now: Date) -> Date? {
        switch self {
        case .days7: now.addingTimeInterval(-7 * 86400)
        case .days30: now.addingTimeInterval(-30 * 86400)
        case .days90: now.addingTimeInterval(-90 * 86400)
        case .all: nil
        }
    }

    public var title: String {
        switch self {
        case .days7: "7 дней"
        case .days30: "30 дней"
        case .days90: "90 дней"
        case .all: "всё"
        }
    }

    /// Попадает ли момент в период.
    public func contains(_ date: Date, now: Date) -> Bool {
        guard let start = start(from: now) else { return true }
        return date >= start
    }
}
